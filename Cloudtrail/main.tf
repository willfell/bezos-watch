module "cloudtrail" {
  source          = "./Modules/cloudtrail"
  aws_account_id  = data.aws_caller_identity.current.account_id
  aws_region_name = data.aws_region.current.name
  company         = var.company
  contact         = var.contact
  service         = var.service
  name            = local.name
  common_tags     = local.common_tags
  alarm_prefix    = var.alarm_prefix
}

module "slack_notifications" {
  source                  = "./Modules/slack-notifications"
  aws_account_id          = data.aws_caller_identity.current.account_id
  aws_region_name         = data.aws_region.current.name
  company                 = var.company
  contact                 = var.contact
  service                 = var.service
  name                    = local.name
  common_tags             = local.common_tags
  alarm_prefix            = var.alarm_prefix
  slack_channel           = var.slack_channel
  slack_token_secret_name = var.slack_token_secret
  slack_token_secret_arn  = data.aws_secretsmanager_secret_version.slack_token.arn

  depends_on = [module.cloudtrail]
}
