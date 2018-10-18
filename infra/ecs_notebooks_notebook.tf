resource "aws_ecs_task_definition" "notebook" {
  family                = "jupyterhub-notebook"
  container_definitions = "${data.template_file.notebook_container_definitions.rendered}"
  execution_role_arn    = "${aws_iam_role.notebook_task_execution.arn}"
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
  }
}

resource "aws_cloudwatch_log_group" "notebook" {
  name = "jupyterhub-notebook"
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

resource "aws_iam_user" "notebooks_task_access" {
  name = "jupyter-notebooks-task-access"
}

resource "aws_iam_access_key" "notebooks_task_access" {
  user = "${aws_iam_user.notebooks_task_access.name}"
}

resource "aws_iam_user_policy" "notebooks_task_access" {
  name   = "notebooks-task-access"
  user   = "${aws_iam_user.notebooks_task_access.name}"
  policy = "${data.aws_iam_policy_document.notebooks_task_access.json}"
}

data "aws_iam_policy_document" "notebooks_task_access" {
  statement {
    actions = [
      "ecs:RunTask",
    ]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values = [
        "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:cluster/${aws_ecs_cluster.notebooks.name}",
      ]
    }

    resources = [
      "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:task-definition/${aws_ecs_task_definition.notebook.family}:*",
    ]
  }

  statement {
    actions = [
      "ecs:StopTask",
    ]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values = [
        "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:cluster/${aws_ecs_cluster.notebooks.name}",
      ]
    }

    resources = [
      "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:task/*",
    ]
  }

  statement {
    actions = [
      "ecs:DescribeTasks",
    ]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values = [
        "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:cluster/${aws_ecs_cluster.notebooks.name}",
      ]
    }

    resources = [
      "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:task/*",
    ]
  }

  statement {
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "${aws_iam_role.notebook_task_execution.arn}"
    ]
  }
}
