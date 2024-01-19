# CloudTrail Alarm Notification

This Python script sends AWS CloudTrail alarm notifications to a specified Slack channel. When an alarm is triggered, it searches the related log group using the metric filter pattern and sends the search results to the Slack channel.

## Dependencies

The following libraries are required:

- `os`: To access environment variables.
- `time`: To get the current time and calculate time ranges.
- `boto3`: To interact with AWS services.
- `json`: To handle JSON data.
- `slack_sdk`: To send messages to the Slack channel.

## Environment Variables

The following environment variable is required:

- `SLACKTOKEN`: Slack API token for sending messages.

## Main Function

The `lambda_handler` function acts as the main entry point. The script executes the following steps:

1. Find the triggered alarm name from the event.
2. Determine the metric name and namespace associated with the alarm.
3. Find the metric filter pattern for the metric.
4. Search the log group using the metric filter pattern.
5. Send an initial message to the Slack channel with the alarm name and a link to the log group console.
6. Send a detailed message to the Slack channel with the search results.

## Slack Notifications

The script uses the `slack_sdk` library to send messages and file uploads to the specified Slack channel. The `SLACKTOKEN` environment variable is required to authenticate with the Slack API.