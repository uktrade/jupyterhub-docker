resource "aws_s3_bucket" "notebooks" {
  bucket = "${var.notebooks_bucket}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_iam_user" "notebooks_s3_access" {
  name = "jupyter-notebooks-s3-access"
}

resource "aws_iam_access_key" "notebooks_s3_access" {
  user = "${aws_iam_user.notebooks_s3_access.name}"
}

resource "aws_iam_user_policy" "notebooks_s3_access" {
  name   = "notebook-s3-access"
  user   = "${aws_iam_user.notebooks_s3_access.name}"
  policy = "${data.aws_iam_policy_document.notebooks_s3_access.json}"
}

data "aws_iam_policy_document" "notebooks_s3_access" {
  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "${aws_s3_bucket.notebooks.arn}",
    ]
  }

  statement {
    actions = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
    ]

    resources = [
      "${aws_s3_bucket.notebooks.arn}/*",
    ]
  }
}
