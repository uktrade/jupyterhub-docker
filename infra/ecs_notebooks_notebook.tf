resource "aws_ecs_task_definition" "notebook" {
  family                = "jupyterhub-notebook"
  container_definitions = "${data.template_file.notebook_container_definitions.rendered}"
  execution_role_arn    = "${aws_iam_role.notebook_task_execution.arn}"
  # task_role_arn         = "${aws_iam_role.notebook_task.arn}"
  network_mode          = "awsvpc"
  cpu                   = "${local.notebook_container_cpu}"
  memory                = "${local.notebook_container_memory}"
  requires_compatibilities = ["FARGATE"]
}

data "template_file" "notebook_container_definitions" {
  template = "${file("${path.module}/ecs_notebooks_notebook_container_definitions.json")}"

  vars {
    container_image  = "${var.notebook_container_image}"
    container_name   = "${local.notebook_container_name}"
    container_cpu    = "${local.notebook_container_cpu}"
    container_memory = "${local.notebook_container_memory}"

    log_group  = "${aws_cloudwatch_log_group.notebook.name}"
    log_region = "${data.aws_region.aws_region.name}"

    logstash_host = "${var.logstash_internal_domain}"
    logstash_port = "${local.logstash_alb_port}"
  }
}

resource "aws_cloudwatch_log_group" "notebook" {
  name              = "jupyterhub-notebook"
  retention_in_days = "3653"
}

resource "aws_iam_role" "notebook_task_execution" {
  name               = "notebook-task-execution"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.notebook_task_execution_ecs_tasks_assume_role.json}"
}

data "aws_iam_policy_document" "notebook_task_execution_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "notebook_task_execution" {
  role       = "${aws_iam_role.notebook_task_execution.name}"
  policy_arn = "${aws_iam_policy.notebook_task_execution.arn}"
}

resource "aws_iam_policy" "notebook_task_execution" {
  name        = "jupyterhub-notebook-task-execution"
  path        = "/"
  policy       = "${data.aws_iam_policy_document.notebook_task_execution.json}"
}

data "aws_iam_policy_document" "notebook_task_execution" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.notebook.arn}",
    ]
  }
}

data "aws_iam_policy_document" "notebook_s3_access_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "notebook_s3_access_template" {
  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "${aws_s3_bucket.notebooks.arn}",
    ]

    condition {
      test = "StringLike"
      variable = "s3:prefix"
      values = [
        "__S3_PREFIX__*"
      ]
    }

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
      "${aws_s3_bucket.notebooks.arn}/__S3_PREFIX__*",
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
      identifiers = ["*"]
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
      identifiers = ["*"]
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

resource "aws_iam_policy" "notebook_task_boundary" {
  name   = "jupyterhub-notebook-task-boundary"
  policy = "${data.aws_iam_policy_document.jupyterhub_notebook_task_boundary.json}"
}

data "aws_iam_policy_document" "jupyterhub_notebook_task_boundary" {
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

resource "aws_vpc_endpoint_route_table_association" "s3" {
  vpc_endpoint_id = "${aws_vpc_endpoint.s3.id}"
  route_table_id  = "${aws_route_table.private_without_egress.id}"
}