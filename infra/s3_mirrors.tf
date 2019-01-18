resource "aws_s3_bucket" "mirrors" {
  bucket = "${var.mirrors_bucket_name}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "mirrors" {
  bucket = "${aws_s3_bucket.mirrors.id}"
  policy = "${data.aws_iam_policy_document.mirrors.json}"
}

data "aws_iam_policy_document" "mirrors" {
  statement {
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:*",
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.mirrors.id}/*",
    ]
    condition {
      test = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }

  # Permission is granted here rather via the notebook role to allow the
  # non-AWS-aware conda cli to GET
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
        "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.mirrors.arn}/*",
    ]

    condition {
      test = "StringEquals"
      variable = "aws:sourceVpce"
      values = [
        "${aws_vpc_endpoint.s3.id}"
      ]
    }
  }
}