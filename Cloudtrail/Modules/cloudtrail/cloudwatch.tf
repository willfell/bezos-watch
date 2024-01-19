################################################################################
# Terraform
################################################################################
locals {
  alarms = {
    authentication-failure   = "{ ($.eventName = ConsoleLogin) && ($.errorMessage = \"Failedauthentication\") }"
    authorization-failure    = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
    aws-config-change        = "{ ($.eventSource = config.amazonaws.com) && (($.eventName=StopConfigurationRecorder) || ($.eventName=DeleteDeliveryChannel) || ($.eventName=PutDeliveryChannel) || ($.eventName=PutConfigurationRecorder)) }"
    cloudtrail-config-change = "{ ($.eventName = CreateTrail) || ($.eventName = UpdateTrail) || ($.eventName = DeleteTrail) || ($.eventName = StartLogging) || ($.eventName = StopLogging) }"
    cmk-disabled-deleted     = "{ ($.eventSource = kms.amazonaws.com) && (($.eventName=DisableKey) || ($.eventName=ScheduleKeyDeletion)) }"
    iam-policy-change        = "{ ($.eventName=DeleteGroupPolicy) || ($.eventName=DeleteRolePolicy) || ($.eventName=DeleteUserPolicy) || ($.eventName=PutGroupPolicy) || ($.eventName=PutRolePolicy) || ($.eventName=PutUserPolicy) || ($.eventName=CreatePolicy) || ($.eventName=DeletePolicy) || ($.eventName=CreatePolicyVersion) || ($.eventName=DeletePolicyVersion) || ($.eventName=AttachRolePolicy)||($.eventName=DetachRolePolicy)||($.eventName=AttachUserPolicy)||($.eventName=DetachUserPolicy)||($.eventName=AttachGroupPolicy)||($.eventName=DetachGroupPolicy) }"
    nacl-change              = "{ ($.eventName = CreateNetworkAcl) || ($.eventName = CreateNetworkAclEntry) || ($.eventName = DeleteNetworkAcl) || ($.eventName = DeleteNetworkAclEntry) || ($.eventName = ReplaceNetworkAclEntry) || ($.eventName = ReplaceNetworkAclAssociation) }"
    network-gateway-change   = "{ ($.eventName = CreateNetworkAcl) || ($.eventName = CreateNetworkAclEntry) || ($.eventName = DeleteNetworkAcl) || ($.eventName = DeleteNetworkAclEntry) || ($.eventName = ReplaceNetworkAclEntry) || ($.eventName = ReplaceNetworkAclAssociation) }"
    root-user-usage          = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"
    route-table-change       = "{ ($.eventName = CreateRoute) || ($.eventName = CreateRouteTable) || ($.eventName = ReplaceRoute) || ($.eventName = ReplaceRouteTableAssociation) || ($.eventName = DeleteRouteTable) || ($.eventName = DeleteRoute) || ($.eventName = DisassociateRouteTable) }"
    s3-bucket-policy-change  = "{ ($.eventSource = s3.amazonaws.com) && (($.eventName = PutBucketAcl) || ($.eventName = PutBucketPolicy) || ($.eventName = PutBucketCors) || ($.eventName = PutBucketLifecycle) || ($.eventName = PutBucketReplication) || ($.eventName = DeleteBucketPolicy) || ($.eventName = DeleteBucketCors) || ($.eventName = DeleteBucketLifecycle) || ($.eventName = DeleteBucketReplication)) }"
    security-group-change    = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }"
    vpc-change               = "{ ($.eventName = CreateVpc) || ($.eventName = DeleteVpc) || ($.eventName = ModifyVpcAttribute) || ($.eventName = AcceptVpcPeeringConnection) || ($.eventName = CreateVpcPeeringConnection) || ($.eventName = DeleteVpcPeeringConnection) || ($.eventName = RejectVpcPeeringConnection) || ($.eventName = AttachClassicLinkVpc) || ($.eventName = DetachClassicLinkVpc) || ($.eventName = DisableVpcClassicLink) || ($.eventName = EnableVpcClassicLink) }"
    secret-change            = "{ $.eventSource = secretsmanager.amazonaws.com && $.eventName = PutSecretValue }"
  }
}

resource "aws_cloudwatch_log_group" "cloudtrail_to_cloudwatch" {
  name              = var.name
  retention_in_days = 30
}

resource "aws_cloudwatch_log_metric_filter" "cloudtrail_metric_filters" {
  for_each = local.alarms

  name           = "${var.alarm_prefix}-${each.key}"
  log_group_name = lower(var.name)
  pattern        = each.value

  metric_transformation {
    name          = "${var.alarm_prefix}-${each.key}"
    namespace     = lower(var.name)
    value         = 1
    default_value = 0
  }
  depends_on = [aws_cloudwatch_log_group.cloudtrail_to_cloudwatch]
}

resource "aws_cloudwatch_metric_alarm" "cloudtrail_metric_alarm" {
  for_each = local.alarms

  alarm_name          = "${var.alarm_prefix}-${each.key}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.cloudtrail_metric_filters[each.key].metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.cloudtrail_metric_filters[each.key].metric_transformation[0].namespace
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "${var.name}-${each.key}"
  treat_missing_data  = "notBreaching"

  alarm_actions             = []
  ok_actions                = []
  insufficient_data_actions = []

  tags = merge(var.common_tags, { Name = "${var.alarm_prefix}-${each.key}" })

  depends_on = [
    aws_cloudwatch_log_metric_filter.cloudtrail_metric_filters
  ]
}