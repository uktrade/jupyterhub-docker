resource "aws_ecs_service" "admin" {
  name            = "${var.prefix}-admin"
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
  name = "${var.prefix}-admin"
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
  family                   = "${var.prefix}-admin"
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
    container_image   = "${var.admin_container_image}"
    container_name    = "${local.admin_container_name}"
    container_command = "[\"/app/start.sh\"]"
    container_port    = "${local.admin_container_port}"
    container_cpu     = "${local.admin_container_cpu}"
    container_memory  = "${local.admin_container_memory}"

    log_group  = "${aws_cloudwatch_log_group.admin.name}"
    log_region = "${data.aws_region.aws_region.name}"


    root_domain               = "${var.admin_domain}"
    admin_db__host            = "${aws_db_instance.admin.address}"
    admin_db__name            = "${aws_db_instance.admin.name}"
    admin_db__password        = "${random_string.aws_db_instance_admin_password.result}"
    admin_db__port            = "${aws_db_instance.admin.port}"
    admin_db__user            = "${aws_db_instance.admin.username}"
    #allowed_hosts_2           = "${aws_service_discovery_service.admin.name}.${aws_service_discovery_private_dns_namespace.jupyterhub.name}"
    authbroker_client_id      = "${var.admin_authbroker_client_id}"
    authbroker_client_secret  = "${var.admin_authbroker_client_secret}"
    authbroker_url            = "${var.admin_authbroker_url}"
    data_db__tiva__host       = "${aws_db_instance.tiva.address}"
    data_db__tiva__name       = "${aws_db_instance.tiva.name}"
    data_db__tiva__password   = "${random_string.aws_db_instance_tiva_password.result}"
    data_db__tiva__port       = "${aws_db_instance.tiva.port}"
    data_db__tiva__user       = "${aws_db_instance.tiva.username}"
    data_db__test_1__host     = "${aws_db_instance.test_1.address}"
    data_db__test_1__name     = "${aws_db_instance.test_1.name}"
    data_db__test_1__password = "${random_string.aws_db_instance_test_1_password.result}"
    data_db__test_1__port     = "${aws_db_instance.test_1.port}"
    data_db__test_1__user     = "${aws_db_instance.test_1.username}"
    # data_db__test_2__host     = "${aws_db_instance.test_2.address}"
    # data_db__test_2__name     = "${aws_db_instance.test_2.name}"
    # data_db__test_2__password = "${random_string.aws_db_instance_test_2_password.result}"
    # data_db__test_2__port     = "${aws_db_instance.test_2.port}"
    # data_db__test_2__user     = "${aws_db_instance.test_2.username}"
    secret_key                = "${random_string.admin_secret_key.result}"

    environment = "${var.admin_environment}"

    #notebooks_bucket = "${var.appstream_bucket}"
    notebooks_bucket = "${var.notebooks_bucket}"

    appstream_url = "https://${var.appstream_domain}/"
    support_url = "https://${var.support_domain}/"

    redis_url = "redis://${aws_elasticache_cluster.admin.cache_nodes.0.address}:6379"

    logstash_host = "${var.logstash_internal_domain}"
    logstash_port = "${local.logstash_alb_port}"
    sentry_dsn = "${var.sentry_dsn}"


    notebook_task_role__role_prefix                        = "${var.notebook_task_role_prefix}"
    notebook_task_role__permissions_boundary_arn           = "${aws_iam_policy.notebook_task_boundary.arn}"
    notebook_task_role__assume_role_policy_document_base64 = "${base64encode(data.aws_iam_policy_document.notebook_s3_access_ecs_tasks_assume_role.json)}"
    notebook_task_role__policy_name                        = "${var.notebook_task_role_policy_name}"
    notebook_task_role__policy_document_template_base64    = "${base64encode(data.aws_iam_policy_document.notebook_s3_access_template.json)}"
    fargate_spawner__aws_region            = "${data.aws_region.aws_region.name}"
    fargate_spawner__aws_ecs_host          = "ecs.${data.aws_region.aws_region.name}.amazonaws.com"
    fargate_spawner__notebook_port         = "${local.notebook_container_port}"
    fargate_spawner__task_custer_name      = "${aws_ecs_cluster.notebooks.name}"
    fargate_spawner__task_container_name   = "${local.notebook_container_name}"
    fargate_spawner__task_definition_arn   = "${aws_ecs_task_definition.notebook.family}:${aws_ecs_task_definition.notebook.revision}"
    fargate_spawner__task_security_group   = "${aws_security_group.notebooks.id}"
    fargate_spawner__task_subnet           = "${aws_subnet.private_without_egress.*.id[0]}"

    fargate_spawner__rstudio_task_definition_arn   = "${aws_ecs_task_definition.rstudio.family}:${aws_ecs_task_definition.rstudio.revision}"

  }
}

resource "aws_ecs_task_definition" "admin_store_db_creds_in_s3" {
  family                   = "${var.prefix}-admin-store-db-creds-in-s3"
  container_definitions    = "${data.template_file.admin_store_db_creds_in_s3_container_definitions.rendered}"
  execution_role_arn       = "${aws_iam_role.admin_task_execution.arn}"
  task_role_arn            = "${aws_iam_role.admin_store_db_creds_in_s3_task.arn}"
  network_mode             = "awsvpc"
  cpu                      = "${local.admin_container_cpu}"
  memory                   = "${local.admin_container_memory}"
  requires_compatibilities = ["FARGATE"]
}

data "template_file" "admin_store_db_creds_in_s3_container_definitions" {
  template = "${file("${path.module}/ecs_main_admin_container_definitions.json")}"

  vars {
    container_image   = "${var.admin_container_image}"
    container_name    = "${local.admin_container_name}"
    container_command = "[\"django-admin\", \"store_db_creds_in_s3\"]"
    container_port    = "${local.admin_container_port}"
    container_cpu     = "${local.admin_container_cpu}"
    container_memory  = "${local.admin_container_memory}"

    log_group  = "${aws_cloudwatch_log_group.admin.name}"
    log_region = "${data.aws_region.aws_region.name}"

    root_domain               = "${var.admin_domain}"
    admin_db__host            = "${aws_db_instance.admin.address}"
    admin_db__name            = "${aws_db_instance.admin.name}"
    admin_db__password        = "${random_string.aws_db_instance_admin_password.result}"
    admin_db__port            = "${aws_db_instance.admin.port}"
    admin_db__user            = "${aws_db_instance.admin.username}"
    authbroker_client_id      = "${var.admin_authbroker_client_id}"
    authbroker_client_secret  = "${var.admin_authbroker_client_secret}"
    authbroker_url            = "${var.admin_authbroker_url}"
    data_db__tiva__host       = "${aws_db_instance.tiva.address}"
    data_db__tiva__name       = "${aws_db_instance.tiva.name}"
    data_db__tiva__password   = "${random_string.aws_db_instance_tiva_password.result}"
    data_db__tiva__port       = "${aws_db_instance.tiva.port}"
    data_db__tiva__user       = "${aws_db_instance.tiva.username}"


    data_db__test_1__host     = "${aws_db_instance.test_1.address}"
    data_db__test_1__name     = "${aws_db_instance.test_1.name}"
    data_db__test_1__password = "${random_string.aws_db_instance_test_1_password.result}"
    data_db__test_1__port     = "${aws_db_instance.test_1.port}"
    data_db__test_1__user     = "${aws_db_instance.test_1.username}"
    # data_db__test_2__host     = "${aws_db_instance.test_2.address}"
    # data_db__test_2__name     = "${aws_db_instance.test_2.name}"
    # data_db__test_2__password = "${random_string.aws_db_instance_test_2_password.result}"
    # data_db__test_2__port     = "${aws_db_instance.test_2.port}"
    # data_db__test_2__user     = "${aws_db_instance.test_2.username}"
    secret_key                = "${random_string.admin_secret_key.result}"

    environment = "${var.admin_environment}"

    #notebooks_bucket = "${var.appstream_bucket}"
    notebooks_bucket = "${var.notebooks_bucket}"

    appstream_url = "https://${var.appstream_domain}/"
    support_url = "https://${var.support_domain}/"

    redis_url = "redis://${aws_elasticache_cluster.admin.cache_nodes.0.address}:6379"

    logstash_host = "${var.logstash_internal_domain}"
    logstash_port = "${local.logstash_alb_port}"
    sentry_dsn = "${var.sentry_dsn}"


    notebook_task_role__role_prefix                        = "${var.notebook_task_role_prefix}"
    notebook_task_role__permissions_boundary_arn           = "${aws_iam_policy.notebook_task_boundary.arn}"
    notebook_task_role__assume_role_policy_document_base64 = "${base64encode(data.aws_iam_policy_document.notebook_s3_access_ecs_tasks_assume_role.json)}"
    notebook_task_role__policy_name                        = "${var.notebook_task_role_policy_name}"
    notebook_task_role__policy_document_template_base64    = "${base64encode(data.aws_iam_policy_document.notebook_s3_access_template.json)}"
    fargate_spawner__aws_region            = "${data.aws_region.aws_region.name}"
    fargate_spawner__aws_ecs_host          = "ecs.${data.aws_region.aws_region.name}.amazonaws.com"
    fargate_spawner__notebook_port         = "${local.notebook_container_port}"
    fargate_spawner__task_custer_name      = "${aws_ecs_cluster.notebooks.name}"
    fargate_spawner__task_container_name   = "${local.notebook_container_name}"
    fargate_spawner__task_definition_arn   = "${aws_ecs_task_definition.notebook.family}:${aws_ecs_task_definition.notebook.revision}"
    fargate_spawner__task_security_group   = "${aws_security_group.notebooks.id}"
    fargate_spawner__task_subnet           = "${aws_subnet.private_without_egress.*.id[0]}"

    fargate_spawner__rstudio_task_definition_arn   = "${aws_ecs_task_definition.rstudio.family}:${aws_ecs_task_definition.rstudio.revision}"
  }
}


resource "random_string" "admin_secret_key" {
  length = 256
  special = false
}

resource "aws_cloudwatch_log_group" "admin" {
  name              = "${var.prefix}-admin"
  retention_in_days = "3653"
}

resource "aws_cloudwatch_log_subscription_filter" "admin" {
  name            = "${var.prefix}-admin"
  log_group_name  = "${aws_cloudwatch_log_group.admin.name}"
  filter_pattern  = ""
  destination_arn = "${var.cloudwatch_destination_arn}"
}

resource "aws_iam_role" "admin_task_execution" {
  name               = "${var.prefix}-admin-task-execution"
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
  name        = "${var.prefix}-admin-task-execution"
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
  name               = "${var.prefix}-admin-task"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.admin_task_ecs_tasks_assume_role.json}"
}


resource "aws_iam_role_policy_attachment" "admin_run_tasks" {
  role       = "${aws_iam_role.admin_task.name}"
  policy_arn = "${aws_iam_policy.admin_run_tasks.arn}"
}

resource "aws_iam_policy" "admin_run_tasks" {
  name        = "${var.prefix}-admin-run-tasks"
  path        = "/"
  policy       = "${data.aws_iam_policy_document.admin_run_tasks.json}"
}

data "aws_iam_policy_document" "admin_run_tasks" {
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
      "arn:aws:ecs:${data.aws_region.aws_region.name}:${data.aws_caller_identity.aws_caller_identity.account_id}:task-definition/${aws_ecs_task_definition.rstudio.family}:*",
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
      "${aws_iam_role.notebook_task_execution.arn}",
    ]
  }

  statement {
    actions = [
      "iam:GetRole",
      "iam:PassRole",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.aws_caller_identity.account_id}:role/${var.notebook_task_role_prefix}*"
    ]
  }

  statement {
    actions = [
      "iam:CreateRole",
      "iam:PutRolePolicy",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.aws_caller_identity.account_id}:role/${var.notebook_task_role_prefix}*"
    ]

    # The boundary means that JupyterHub can't create abitrary roles:
    # they must have this boundary attached. At most, they will
    # be able to have access to the entire bucket, and only
    # from inside the VPC
    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = [
        "${aws_iam_policy.notebook_task_boundary.arn}",
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "admin_admin_store_db_creds_in_s3_task" {
  role       = "${aws_iam_role.admin_task.name}"
  policy_arn = "${aws_iam_policy.admin_store_db_creds_in_s3_task.arn}"
}

resource "aws_iam_role" "admin_store_db_creds_in_s3_task" {
  name               = "${var.prefix}-admin-store-db-creds-in-s3-task"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.admin_task_ecs_tasks_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "admin_store_db_creds_in_s3_task" {
  role       = "${aws_iam_role.admin_store_db_creds_in_s3_task.name}"
  policy_arn = "${aws_iam_policy.admin_store_db_creds_in_s3_task.arn}"
}

resource "aws_iam_policy" "admin_store_db_creds_in_s3_task" {
  name        = "${var.prefix}-admin-store-db-creds-in-s3-task"
  path        = "/"
  policy       = "${data.aws_iam_policy_document.admin_store_db_creds_in_s3_task.json}"
}

data "aws_iam_policy_document" "admin_store_db_creds_in_s3_task" {
  statement {
    actions = [
        "s3:PutObject",
        "s3:PutObjectAcl",
    ]

    resources = [
      "${aws_s3_bucket.notebooks.arn}/*",
      "arn:aws:s3:::appstream2-36fb080bb8-eu-west-1-664841488776/*",
    ]
  }
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
  name            = "${var.prefix}-admin"
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
  protocol    = "HTTP"
  vpc_id      = "${aws_vpc.main.id}"
  target_type = "ip"

  health_check {
    path = "/healthcheck"
    protocol = "HTTP"
    healthy_threshold = 3
    unhealthy_threshold = 2
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elasticache_cluster" "admin" {
  cluster_id           = "${var.prefix_short}-admin"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  engine_version       = "5.0.3"
  port                 = 6379
  subnet_group_name    = "${aws_elasticache_subnet_group.admin.name}"
  security_group_ids   = ["${aws_security_group.admin_redis.id}"]
}

resource "aws_elasticache_subnet_group" "admin" {
  name               = "${var.prefix_short}-admin"
  subnet_ids         = ["${aws_subnet.private_with_egress.*.id}"]
}
