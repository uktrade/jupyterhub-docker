resource "aws_ecs_service" "jupyterhub" {
  name            = "jupyterhub"
  cluster         = "${aws_ecs_cluster.main_cluster.id}"
  task_definition = "${aws_ecs_task_definition.jupyterhub.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = ["${aws_subnet.private_with_egress.*.id}"]
    security_groups = ["${aws_security_group.jupyterhub_service.id}"]
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.jupyterhub.arn}"
    container_port   = "${local.jupyterhub_container_port}"
    container_name   = "${local.jupyterhub_container_name}"
  }

  depends_on = [
    # The target group must have been associated with the listener first
    "aws_alb_listener.jupyterhub",
  ]
}

resource "aws_ecs_task_definition" "jupyterhub" {
  family                   = "jupyterhub"
  container_definitions    = "${data.template_file.jupyterhub_container_definitions.rendered}"
  execution_role_arn       = "${aws_iam_role.jupyterhub_task_execution.arn}"
  network_mode             = "awsvpc"
  cpu                      = "${local.jupyterhub_container_cpu}"
  memory                   = "${local.jupyterhub_container_memory}"
  requires_compatibilities = ["FARGATE"]
}

data "template_file" "jupyterhub_container_definitions" {
  template = "${file("${path.module}/ecs_main_jupyterhub_container_definitions.json")}"

  vars {
    container_image  = "${var.jupyterhub_container_image}"
    container_name   = "${local.jupyterhub_container_name}"
    container_port   = "${local.jupyterhub_container_port}"
    container_cpu    = "${local.jupyterhub_container_cpu}"
    container_memory = "${local.jupyterhub_container_memory}"

    log_group  = "${aws_cloudwatch_log_group.jupyterhub.name}"
    log_region = "${data.aws_region.aws_region.name}"

    db_url      = "postgres://${aws_db_instance.jupyterhub.username}:${aws_db_instance.jupyterhub.password}@${aws_db_instance.jupyterhub.endpoint}/${aws_db_instance.jupyterhub.name}?sslmode=require"
    admin_users = "${var.jupyterhub_admin_users}"

    configproxy_auth_token = "${random_string.jupyterhub_container_configproxy_auth_token.result}"
    jpy_cookie_secret = "${random_id.jupyterhub_container_jpy_cookie_secret.hex}"
    jupyterhub_crypt_key = "${random_id.jupyterhub_container_jupyterhub_crypt_key.hex}"

    oauth_callback_url = "https://${var.jupyterhub_domain}${local.jupyterhub_oauth_callback_path}"
    oauth_client_id = "${var.jupyterhub_oauth_client_id}"
    oauth_client_secret = "${var.jupyterhub_oauth_client_secret}"
    oauth2_authorize_url = "${var.jupyterhub_oauth_authorize_url}"
    oauth2_token_url = "${var.jupyterhub_oauth_token_url}"
    oauth2_userdata_url = "${var.jupyterhub_oauth_userdata_url}"
    oauth2_username_key = "${local.jupyterhub_oauth_username_key}"

    database_access__url = "https://${aws_service_discovery_service.admin.name}.${aws_service_discovery_private_dns_namespace.jupyterhub.name}:${local.admin_container_port}${local.admin_api_path}"

    fargate_spawner__aws_region            = "${data.aws_region.aws_region.name}"
    fargate_spawner__aws_access_key_id     = "${aws_iam_access_key.notebooks_task_access.id}"
    fargate_spawner__aws_secret_access_key = "${aws_iam_access_key.notebooks_task_access.secret}"
    fargate_spawner__aws_host              = "ecs.${data.aws_region.aws_region.name}.amazonaws.com"
    fargate_spawner__notebook_port         = "${local.notebook_container_port}"
    fargate_spawner__task_custer_name      = "${aws_ecs_cluster.notebooks.name}"
    fargate_spawner__task_container_name   = "${local.notebook_container_name}"
    fargate_spawner__task_definition_arn   = "${aws_ecs_task_definition.notebook.family}:${aws_ecs_task_definition.notebook.revision}"
    fargate_spawner__task_security_group   = "${aws_security_group.notebooks.id}"
    fargate_spawner__task_subnet           = "${aws_subnet.private_with_egress.*.id[0]}"  # To be changed to limit egress

    jpynb_s3_access_key_id = "${aws_iam_access_key.notebooks_s3_access.id}"
    jpynb_s3_secret_access_key = "${aws_iam_access_key.notebooks_s3_access.secret}"
    jpynb_s3_bucket_name = "${aws_s3_bucket.notebooks.id}"
    jpynb_s3_region_name = "${data.aws_region.aws_region.name}"
  }
}

resource "random_string" "jupyterhub_container_configproxy_auth_token" {
  length = 256
  special = false
}

resource "random_id" "jupyterhub_container_jpy_cookie_secret" {
  byte_length = 256
}

resource "random_id" "jupyterhub_container_jupyterhub_crypt_key" {
  byte_length = 32
}

resource "aws_cloudwatch_log_group" "jupyterhub" {
  name = "jupyterhub"
}

resource "aws_iam_role" "jupyterhub_task_execution" {
  name               = "jupyterhub-task-execution"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.jupyterhub_task_execution.json}"
}

data "aws_iam_policy_document" "jupyterhub_task_execution" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "jupyterhub_task_execution" {
  role       = "${aws_iam_role.jupyterhub_task_execution.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_alb" "jupyterhub" {
  name            = "jupyterhub"
  subnets         = ["${aws_subnet.public.*.id}"]
  security_groups = ["${aws_security_group.jupyterhub_alb.id}"]
}

resource "aws_alb_listener" "jupyterhub" {
  load_balancer_arn = "${aws_alb.jupyterhub.arn}"
  port              = "${local.jupyterhub_alb_port}"
  protocol          = "HTTPS"

  default_action {
    target_group_arn = "${aws_alb_target_group.jupyterhub.arn}"
    type             = "forward"
  }

  certificate_arn = "${aws_acm_certificate_validation.jupyterhub.certificate_arn}"
}

resource "aws_alb_target_group" "jupyterhub" {
  name_prefix = "jh-"
  port        = "${local.jupyterhub_target_group_port}"
  protocol    = "HTTPS"
  vpc_id      = "${aws_vpc.main.id}"
  target_type = "ip"

  health_check {
    path = "/favicon.ico"
    protocol = "HTTPS"
    healthy_threshold = 3
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}
