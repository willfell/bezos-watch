import os
import time
import boto3
import json
from slack_sdk import WebClient

client = boto3.client("logs")
slack_channel = os.environ["SLACKCHANNEL"]
SLACKTOKENSECRET = os.environ["SLACKTOKENSECRET"]
log_group = os.environ['LOGGROUP']
now = int(time.time() * 1000)
fifteen_min_ago = int((time.time() - 900) * 1000)
search_log_group_console = "https://us-east-2.console.aws.amazon.com/cloudwatch/home?region=us-east-2#logsV2:log-groups/log-group/radware/log-events"

# test
def lambda_handler(event, context):
    def find_alarm(event):
        print("------------------------------")
        print("Gathering information about the alert")
        print("Alarm name = " + event["detail"]["alarmName"])
        return event["detail"]["alarmName"]

    def find_metric_name(alarm_name):
        print("------------------------------")
        print("Determining Metric Name from Alarm Name")
        client = boto3.client("cloudwatch")
        response = client.describe_alarms(
            AlarmNames=[
                alarm_name,
            ],
        )
        metric_info = []
        metric_info.append(response["MetricAlarms"][0]["MetricName"])
        metric_info.append(response["MetricAlarms"][0]["Namespace"])
        print("Metric Name = " + metric_info[0])
        print("Metric Namespace = " + metric_info[1])
        return metric_info

    def find_metric_pattern(metric_name, metric_namespace):
        print("------------------------------")
        print("Finding Metric Filter Pattern")
        client = boto3.client("logs")
        response = client.describe_metric_filters(
            metricName=metric_name, metricNamespace=metric_namespace
        )
        metric_filter_pattern = response["metricFilters"][0]["filterPattern"]
        return metric_filter_pattern

    def search_log_group(metric_filter_pattern):
        logs_found = False
        max_attempts = 10
        n = 1

        while n <= max_attempts and not logs_found:
            print("------------------------------")
            print(f"Searching Log Group using Metric Filter | Attempt {n}")
            logclient = boto3.client("logs")
            paginator = client.get_paginator("filter_log_events")
            response_iterator = paginator.paginate(
                logGroupName=log_group,
                startTime=fifteen_min_ago,
                endTime=now,
                filterPattern=metric_filter_pattern,
            )

            for page in response_iterator:
                if page["events"]:
                    logs_found = True
                    break

            if not logs_found:
                n += 1
                if n <= max_attempts:
                    print("No events found, retrying")
                    time.sleep(5)

        if not logs_found:
            print("Max attempts reached, returning empty string")

        log_events = []
        for page in response_iterator:
            for event in page["events"]:
                event_json = json.loads(event["message"])
                event_json = json.dumps(event_json, indent=4)
                log_events.append(event_json)

        # Make Log Events Pretty for Slack
        log_events_pretty = ""
        for log in log_events:
            log = json.loads(log)
            log = json.dumps(log, indent=4)
            log_events_pretty += (
                "\n" + "------------------------------------------" + "\n"
            )
            log_events_pretty += log + "\n\n"

        return log_events_pretty

    def get_slack_token():
        client = boto3.client("secretsmanager")
        response = client.get_secret_value(SecretId=SLACKTOKENSECRET)
        
        return response["SecretString"]

    def initial_notification(alarm_name):
        print("------------------------------")
        print("Sending initial details to ", slack_channel)
        slack_token = get_slack_token()
        client = WebClient(token=slack_token)
        initial_notification = client.chat_postMessage(
            channel=slack_channel,
            text="CloudTrail",
            blocks=[
                {
                    "type": "header",
                    "text": {"type": "plain_text", "text": "CloudTrail"},
                },
                {"type": "divider"},
                {
                    "type": "section",
                    "text": {"type": "mrkdwn", "text": "`" + alarm_name + "`"},
                    "accessory": {
                        "type": "button",
                        "text": {"type": "plain_text", "text": "Search Log Group"},
                        "url": search_log_group_console,
                    },
                },
            ],
        )
        return initial_notification["ts"]

    def notification_details(thread_id, log_events, alarm_name, metric_filter_pattern):
        print("Sending log group search results to", slack_channel)
        slack_token = get_slack_token()
        client = WebClient(token=slack_token)
        if log_events != "":
            notification_details = client.files_upload(
                channels=slack_channel, thread_ts=thread_id, content=log_events
            )
        else:
            print("No events found, sending notification with metric filter pattern")
            no_event_found_notification = client.chat_postMessage(
                channel=slack_channel,
                thread_ts=thread_id,
                text="No Event Found | CloudTrail Alert",
                blocks=[
                    {
                        "type": "section",
                        "text": {"type": "mrkdwn", "text": "No events were found"},
                    },
                    {"type": "divider"},
                    {
                        "type": "section",
                        "text": {
                            "type": "mrkdwn",
                            "text": "Metric Filter Pattern\n\n```"
                            + metric_filter_pattern
                            + "```",
                        },
                    },
                ],
            )

    # Figure out what alarm is going off
    alarm_name = find_alarm(event)

    # Gather information on the metric that started the alarm
    metric_info = find_metric_name(alarm_name)
    metric_name = metric_info[0]
    metric_namespace = metric_info[1]

    # Obtain the Metric Filter Pattern
    metric_filter_pattern = find_metric_pattern(metric_name, metric_namespace)

    # Search the log group with the Metric Filter Pattern
    log_events = search_log_group(metric_filter_pattern)

    # Post the results of log group search into slack
    thread_id = initial_notification(alarm_name)
    notification_details(thread_id, log_events, alarm_name, metric_filter_pattern)