data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_secretsmanager_secret" "slack_token" {
  name = var.slack_token_secret
}

data "aws_secretsmanager_secret_version" "slack_token" {
  secret_id = data.aws_secretsmanager_secret.slack_token.id
}
