################################################################################
# Cloudtrail
################################################################################

resource "aws_kms_key" "cloud_trail_kms_key" {
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  description              = "KMS key for ${var.name}"
  deletion_window_in_days  = 7
  enable_key_rotation      = true
  is_enabled               = true
  key_usage                = "ENCRYPT_DECRYPT"
  multi_region             = false

  policy = data.aws_iam_policy_document.cloudtrail_kms.json

  tags = merge(var.common_tags, tomap({ "Name" = var.name }))
}

resource "aws_kms_alias" "cloud_trail_kms_key_alias" {
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.cloud_trail_kms_key.key_id
}

resource "aws_iam_role" "cloudwatch_to_cloudtrail" {
  name               = "CloudTrailRoleForCloudWatchLogs_${var.name}"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_to_cloudwatch_assume_role_policy.json

  tags = merge(var.common_tags, tomap({ "Name" = "CloudTrailRoleForCloudWatchLogs_${var.name}" }))
}

resource "aws_iam_policy" "cloudtrail_to_cloudwatch" {
  name   = "CloudTrailRoleForCloudWatchLogs_${var.name}"
  policy = data.aws_iam_policy_document.cloudtrail_to_cloudwatch.json

  tags = merge(var.common_tags, tomap({ "Name" = "CloudTrailRoleForCloudWatchLogs_${var.name}" }))
}

resource "aws_iam_role_policy_attachment" "cloudtrail_to_cloudwatch" {
  role       = aws_iam_role.cloudwatch_to_cloudtrail.name
  policy_arn = aws_iam_policy.cloudtrail_to_cloudwatch.arn
}

resource "aws_cloudtrail" "cloudtrail" {
  name                          = var.name
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail_to_cloudwatch.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudwatch_to_cloudtrail.arn
  enable_log_file_validation    = true
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  include_global_service_events = true
  kms_key_id                    = aws_kms_alias.cloud_trail_kms_key_alias.target_key_arn
  is_multi_region_trail         = true

  tags       = merge(var.common_tags, tomap({ "Name" = var.name }))
  depends_on = [aws_cloudwatch_log_group.cloudtrail_to_cloudwatch]
}
