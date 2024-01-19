data "aws_iam_policy_document" "cloudtrail_s3_policy" {
  version = "2012-10-17"

  statement {
    sid       = "AWSCloudTrailAclCheck20150319"
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::${lower(var.company)}-${var.name}}"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }

  statement {
    sid       = "AWSCloudTrailWrite20150319"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${lower(var.company)}-${var.name}}/AWSLogs/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid     = "ForceSSLOnlyAccess"
    actions = ["s3:*"]
    effect  = "Deny"

    resources = [
      "arn:aws:s3:::${lower(var.company)}-${var.name}}",
      "arn:aws:s3:::${lower(var.company)}-${var.name}}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

data "aws_iam_policy_document" "cloudtrail_to_cloudwatch_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cloudtrail_to_cloudwatch" {
  version = "2012-10-17"

  statement {
    sid    = "AWSCloudTrailCreateLogStream2014110"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
    ]
    resources = [
      "arn:aws:logs:${var.aws_region_name}:${var.aws_account_id}:log-group:${var.name}:log-stream:${var.aws_account_id}_CloudTrail_${var.aws_region_name}*"
    ]
  }

  statement {
    sid    = "AWSCloudTrailPutLogEvents20141101"
    effect = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region_name}:${var.aws_account_id}:log-group:${var.name}:log-stream:${var.aws_account_id}_CloudTrail_${var.aws_region_name}*"
    ]
  }
}

data "aws_iam_policy_document" "cloudtrail_kms" {
  version = "2012-10-17"

  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "Allow CloudTrail service to encrypt/decrypt"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["kms:GenerateDataKey*", "kms:Decrypt"]
    resources = ["*"]
  }

  statement {
    sid    = "Allow CloudTrail to describe key"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["kms:DescribeKey"]
    resources = ["*"]
  }

  statement {
    sid    = "Allow SNS service to encrypt/decrypt"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = ["kms:GenerateDataKey*", "kms:Decrypt"]
    resources = ["*"]

  }

  statement {
    sid    = "Allow principals in the account to decrypt log files"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "kms:Decrypt",
      "kms:ReEncryptFrom"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [var.aws_account_id]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:aws:cloudtrail:*:${var.aws_account_id}:trail/*"]
    }
  }
}

