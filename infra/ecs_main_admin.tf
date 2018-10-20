resource "aws_ecs_service" "admin" {
  name            = "jupyterhub-admin"
  cluster         = "${aws_ecs_cluster.main_cluster.id}"
  task_definition = "${aws_ecs_task_definition.admin.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = ["${aws_subnet.private_with_egress.*.id}"]
    security_groups = ["${aws_security_group.admin_service.id}"]
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.admin.arn}"
    container_port   = "${local.admin_container_port}"
    container_name   = "${local.admin_container_name}"
  }

  service_registries {
    registry_arn   = "${aws_service_discovery_service.admin.arn}"
  }

  depends_on = [
    # The target group must have been associated with the listener first
    "aws_alb_listener.admin",
  ]
}

resource "aws_service_discovery_service" "admin" {
  name = "jupyterhub-admin"
  dns_config {
    namespace_id = "${aws_service_discovery_private_dns_namespace.jupyterhub.id}"
    dns_records {
      ttl = 10
      type = "A"
    }
  }

  # Needed for a service to be able to register instances with a target group,
  # but only if it has a service_registries, which we do
  # https://forums.aws.amazon.com/thread.jspa?messageID=852407&tstart=0
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_task_definition" "admin" {
  family                   = "jupyterhub-admin"
  container_definitions    = "${data.template_file.admin_container_definitions.rendered}"
  execution_role_arn       = "${aws_iam_role.admin_task_execution.arn}"
  task_role_arn            = "${aws_iam_role.admin_task.arn}"
  network_mode             = "awsvpc"
  cpu                      = "${local.admin_container_cpu}"
  memory                   = "${local.admin_container_memory}"
  requires_compatibilities = ["FARGATE"]
}

data "template_file" "admin_container_definitions" {
  template = "${file("${path.module}/ecs_main_admin_container_definitions.json")}"

  vars {
    container_image  = "${var.admin_container_image}"
    container_name   = "${local.admin_container_name}"
    container_port   = "${local.admin_container_port}"
    container_cpu    = "${local.admin_container_cpu}"
    container_memory = "${local.admin_container_memory}"

    log_group  = "${aws_cloudwatch_log_group.admin.name}"
    log_region = "${data.aws_region.aws_region.name}"

    admin_db__host            = "${aws_db_instance.admin.address}"
    admin_db__name            = "${aws_db_instance.admin.name}"
    admin_db__password        = "${random_string.aws_db_instance_admin_password.result}"
    admin_db__port            = "${aws_db_instance.admin.port}"
    admin_db__user            = "${aws_db_instance.admin.username}"
    allowed_hosts_1           = "${var.admin_domain}"
    allowed_hosts_2           = "${aws_service_discovery_service.admin.name}.${aws_service_discovery_private_dns_namespace.jupyterhub.name}"
    authbroker_client_id      = "${var.admin_authbroker_client_id}"
    authbroker_client_secret  = "${var.admin_authbroker_client_secret}"
    authbroker_url            = "${var.admin_authbroker_url}"
    data_db__test_1__host     = "${aws_db_instance.test_1.address}"
    data_db__test_1__name     = "${aws_db_instance.test_1.name}"
    data_db__test_1__password = "${random_string.aws_db_instance_test_1_password.result}"
    data_db__test_1__port     = "${aws_db_instance.test_1.port}"
    data_db__test_1__user     = "${aws_db_instance.test_1.username}"
    data_db__test_2__host     = "${aws_db_instance.test_2.address}"
    data_db__test_2__name     = "${aws_db_instance.test_2.name}"
    data_db__test_2__password = "${random_string.aws_db_instance_test_2_password.result}"
    data_db__test_2__port     = "${aws_db_instance.test_2.port}"
    data_db__test_2__user     = "${aws_db_instance.test_2.username}"
    secret_key                = "${random_string.admin_secret_key.result}"
  }
}

resource "random_string" "admin_secret_key" {
  length = 256
  special = false
}

resource "aws_cloudwatch_log_group" "admin" {
  name              = "jupyterhub-admin"
  retention_in_days = "3653"
}

resource "aws_iam_role" "admin_task_execution" {
  name               = "admin-task-execution"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.admin_task_execution_ecs_tasks_assume_role.json}"
}

data "aws_iam_policy_document" "admin_task_execution_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "admin_task_execution" {
  role       = "${aws_iam_role.admin_task_execution.name}"
  policy_arn = "${aws_iam_policy.admin_task_execution.arn}"
}

resource "aws_iam_policy" "admin_task_execution" {
  name        = "jupyterhub-admin-task-execution"
  path        = "/"
  policy       = "${data.aws_iam_policy_document.admin_task_execution.json}"
}

data "aws_iam_policy_document" "admin_task_execution" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.admin.arn}",
    ]
  }
}

resource "aws_iam_role" "admin_task" {
  name               = "jupyterhub-admin-task"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.admin_task_ecs_tasks_assume_role.json}"
}

data "aws_iam_policy_document" "admin_task_ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_alb" "admin" {
  name            = "jupyterhub-admin"
  subnets         = ["${aws_subnet.public.*.id}"]
  security_groups = ["${aws_security_group.admin_alb.id}"]

  access_logs {
    bucket  = "${aws_s3_bucket.alb_access_logs.id}"
    prefix  = "admin"
    enabled = true
  }

  depends_on = [
    "aws_s3_bucket_policy.alb_access_logs",
  ]
}

resource "aws_alb_listener" "admin" {
  load_balancer_arn = "${aws_alb.admin.arn}"
  port              = "${local.admin_alb_port}"
  protocol          = "HTTPS"

  default_action {
    target_group_arn = "${aws_alb_target_group.admin.arn}"
    type             = "forward"
  }

  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = "${aws_acm_certificate_validation.admin.certificate_arn}"
}

resource "aws_alb_target_group" "admin" {
  name_prefix = "jhadm-"
  port        = "${local.admin_container_port}"
  protocol    = "HTTPS"
  vpc_id      = "${aws_vpc.main.id}"
  target_type = "ip"

  health_check {
    path = "/healthcheck"
    protocol = "HTTPS"
    healthy_threshold = 3
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}
