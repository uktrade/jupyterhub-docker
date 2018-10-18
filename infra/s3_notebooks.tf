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

    condition {
      test = "StringEquals"
      variable = "aws:sourceVpce"
      values = [
        "${aws_vpc_endpoint.s3.id}"
      ]
    }
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

    condition {
      test = "StringEquals"
      variable = "aws:sourceVpce"
      values = [
        "${aws_vpc_endpoint.s3.id}"
      ]
    }
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = "${aws_vpc.main.id}"
  service_name      = "com.amazonaws.${data.aws_region.aws_region.name}.s3"
  vpc_endpoint_type = "Gateway"

  policy = "${data.aws_iam_policy_document.aws_vpc_endpoint_s3_notebooks.json}"
}

data "aws_iam_policy_document" "aws_vpc_endpoint_s3_notebooks" {
  statement {
    principals {
      type = "AWS"
      identifiers = ["${aws_iam_user.notebooks_s3_access.unique_id}"]
    }

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "${aws_s3_bucket.notebooks.arn}",
    ]
  }

  statement {
    principals {
      type = "AWS"
      identifiers = ["${aws_iam_user.notebooks_s3_access.unique_id}"]
    }

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

resource "aws_vpc_endpoint_route_table_association" "s3" {
  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
  route_table_id  = "${aws_route_table.private_without_egress.id}"
}
