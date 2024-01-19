################################################################################
# S3
################################################################################
# data "aws_s3_bucket" "access_logs_s3" {
#   bucket = lower("${var.aws_account_id}-${var.aws_region_name}-s3-logs")
# }

data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
  statement {
    actions = [
      "s3:*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      aws_s3_bucket.cloudtrail_bucket.arn,
      "${aws_s3_bucket.cloudtrail_bucket.arn}/*",
    ]
    sid = "DenyUnSecureCommunications"
  }

  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "cloudtrail.amazonaws.com"
      ]
    }
    actions = [
      "s3:GetBucketAcl"
    ]
    resources = [
      aws_s3_bucket.cloudtrail_bucket.arn
    ]
  }
  statement {
    sid    = "AWSCloudrailWrite"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "cloudtrail.amazonaws.com"
      ]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.cloudtrail_bucket.arn}/AWSLogs/${var.aws_account_id}/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values = [
        "bucket-owner-full-control"
      ]
    }
  }
  # statement {
  #   sid    = "SNSNotification"
  #   effect = "Allow"
  #   principals {
  #     type = "Service"
  #     identifiers = [
  #       "sns.amazonaws.com"
  #     ]
  #   }
  #   actions = [
  #     "s3:*"
  #   ]
  #   resources = [
  #     aws_s3_bucket.cloudtrail_bucket.arn,
  #     "${aws_s3_bucket.cloudtrail_bucket.arn}/*",
  #     "${aws_s3_bucket.cloudtrail_bucket.arn}/AWSLogs/*",
  #   ]
  # }
}


resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = "${lower(var.company)}-${var.name}"
  force_destroy = true

  tags = merge(var.common_tags, tomap({ "Name" = "${lower(var.company)}-${var.name}" }))
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lb_access_logs" {
  bucket = aws_s3_bucket.cloudtrail_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket_policy.json
}

resource "aws_s3_bucket_versioning" "cloudtrail_bucket_versioning" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  versioning_configuration {
    status = "Suspended"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_bucket_public_access_block" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# resource "aws_s3_bucket_logging" "cloudtrail_bucket_logging" {
#   bucket = aws_s3_bucket.cloudtrail_bucket.bucket
#   target_bucket = data.aws_s3_bucket.access_logs_s3.id
#   target_prefix = "${aws_s3_bucket.cloudtrail_bucket.bucket}/"
# }

