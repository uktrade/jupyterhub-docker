resource "aws_ecs_service" "logstash" {
  name            = "jupyterhub-logstash"
  cluster         = "${aws_ecs_cluster.main_cluster.id}"
  task_definition = "${aws_ecs_task_definition.logstash.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = ["${aws_subnet.private_with_egress.*.id}"]
    security_groups = ["${aws_security_group.logstash_service.id}"]
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.logstash.arn}"
    container_port   = "${local.logstash_container_port}"
    container_name   = "${local.logstash_container_name}"
  }

  depends_on = [
    # The target group must have been associated with the listener first
    "aws_alb_listener.logstash",
  ]
}

resource "aws_ecs_task_definition" "logstash" {
  family                = "jupyterhub-logstash"
  container_definitions = "${data.template_file.logstash_container_definitions.rendered}"
  execution_role_arn    = "${aws_iam_role.logstash_task_execution.arn}"
  task_role_arn         = "${aws_iam_role.logstash_task.arn}"
  network_mode          = "awsvpc"
  cpu                   = "${local.logstash_container_cpu}"
  memory                = "${local.logstash_container_memory}"
  requires_compatibilities = ["FARGATE"]
}

data "template_file" "logstash_container_definitions" {
  template = "${file("${path.module}/ecs_main_logstash_container_definitions.json")}"

  vars {
    container_image    = "${var.logstash_container_image}"
    container_name     = "${local.logstash_container_name}"
    container_port     = "${local.logstash_container_port}"
    container_api_port = "${local.logstash_container_api_port}"
    container_cpu      = "${local.logstash_container_cpu}"
    container_memory   = "${local.logstash_container_memory}"

    log_group  = "${aws_cloudwatch_log_group.logstash.name}"
    log_region = "${data.aws_region.aws_region.name}"

    logstash_downstream_url                  = "${var.logstash_downstream_url}"
    logstash_downstream_authorization_header = "${var.logstash_downstream_authorization_header}"
  }
}

resource "aws_cloudwatch_log_group" "logstash" {
  name              = "jupyterhub-logstash"
  retention_in_days = "3653"
}

resource "aws_cloudwatch_log_subscription_filter" "logstash" {
  name            = "jupyterhub-logstash"
  log_group_name  = "${aws_cloudwatch_log_group.logstash.name}"
  filter_pattern  = ""
  destination_arn = "${var.cloudwatch_destination_arn}"
}

resource "aws_iam_role" "logstash_task_execution" {
  name               = "logstash-task-execution"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.logstash_task_execution_ecs_tasks_assume_role.json}"
}

data "aws_iam_policy_document" "logstash_task_execution_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "logstash_task_execution" {
  role       = "${aws_iam_role.logstash_task_execution.name}"
  policy_arn = "${aws_iam_policy.logstash_task_execution.arn}"
}

resource "aws_iam_policy" "logstash_task_execution" {
  name        = "jupyterhub-logstash-task-execution"
  path        = "/"
  policy       = "${data.aws_iam_policy_document.logstash_task_execution.json}"
}

data "aws_iam_policy_document" "logstash_task_execution" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.logstash.arn}",
    ]
  }
}

resource "aws_iam_role" "logstash_task" {
  name               = "jupyterhub-logstash-task"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.logstash_task_ecs_tasks_assume_role.json}"
}

data "aws_iam_policy_document" "logstash_task_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_alb" "logstash" {
  name            = "jupyterhub-logstash"
  subnets         = ["${aws_subnet.private_with_egress.*.id}"]
  security_groups = ["${aws_security_group.logstash_alb.id}"]
  internal        = true

  access_logs {
    bucket  = "${aws_s3_bucket.alb_access_logs.id}"
    prefix  = "logstash"
    enabled = true
  }

  depends_on = [
    "aws_s3_bucket_policy.alb_access_logs",
  ]
}

resource "aws_alb_listener" "logstash" {
  load_balancer_arn = "${aws_alb.logstash.arn}"
  port              = "${local.logstash_alb_port}"
  protocol          = "HTTPS"

  default_action {
    target_group_arn = "${aws_alb_target_group.logstash.arn}"
    type             = "forward"
  }

  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = "${aws_acm_certificate_validation.logstash.certificate_arn}"
}

resource "aws_alb_target_group" "logstash" {
  name_prefix = "jhlog-"
  port        = "${local.logstash_container_port}"
  protocol    = "HTTPS"
  vpc_id      = "${aws_vpc.main.id}"
  target_type = "ip"

  health_check {
    port = "${local.logstash_container_api_port}"
    protocol = "HTTP"
    healthy_threshold = 5
    unhealthy_threshold = 3
  }

  lifecycle {
    create_before_destroy = true
  }
}
