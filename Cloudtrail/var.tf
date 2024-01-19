locals {
  common_tags = {
    Contact     = var.contact
    DeployedBy  = "Automation:Terraform"
    Environment = local.environment
    Service     = var.service
  }
  environment = "Prod"
  name        = var.service
}

variable "company" {
  default = "bezos-watch-cloudtrail"
}

variable "contact" {
  default = "foobar@gmail.com"
}

variable "service" {
  default = "cloudtrail"
}

variable "alarm_prefix" {
  default = "security-events"
}

variable "slack_channel" {
  default = "#aws-notifications"
}

variable "slack_token_secret" {
  default = "slack/aws-notifications"
}
