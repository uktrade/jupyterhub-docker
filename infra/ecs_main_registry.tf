resource "aws_ecs_service" "registry" {
  name            = "jupyterhub-registry"
  cluster         = "${aws_ecs_cluster.main_cluster.id}"
  task_definition = "${aws_ecs_task_definition.registry.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"

  # iam_role = "${aws_iam_role.registry_ecs_service.name}"

  network_configuration {
    subnets         = ["${data.aws_subnet.private_subnets_with_egress.*.id}"]
    security_groups = ["${aws_security_group.registry_service.id}"]
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.registry.arn}"
    container_port   = "${local.registry_container_port}"
    container_name   = "${local.registry_container_name}"
  }

  depends_on = [
    # The target group must have been associated with the listener first
    "aws_alb_listener.registry",
  ]
}

resource "aws_ecs_task_definition" "registry" {
  family                = "jupyterhub-registry"
  container_definitions = "${data.template_file.registry_container_definitions.rendered}"
  execution_role_arn    = "${aws_iam_role.registry_task_execution.arn}"
  network_mode          = "awsvpc"
  cpu                   = "${local.registry_container_cpu}"
  memory                = "${local.registry_container_memory}"
  requires_compatibilities = ["FARGATE"]
}

data "template_file" "registry_container_definitions" {
  template = "${file("${path.module}/ecs_main_registry_container_definitions.json")}"

  vars {
    container_image  = "${var.registry_container_image}"
    container_name   = "${local.registry_container_name}"
    container_port   = "${local.registry_container_port}"
    container_cpu    = "${local.registry_container_cpu}"
    container_memory = "${local.registry_container_memory}"

    log_group  = "${aws_cloudwatch_log_group.registry.name}"
    log_region = "${data.aws_region.aws_region.name}"

    registry_proxy_remoteurl = "${var.registry_proxy_remoteurl}"
    registry_proxy_username  = "${var.registry_proxy_username}"
    registry_proxy_password  = "${var.registry_proxy_password}"
  }
}

# resource "aws_iam_role" "registry_ecs_service" {
#   name               = "jupyterhub-registry"
#   path               = "/"
#   assume_role_policy = "${data.aws_iam_policy_document.registry_ecs_service.json}"
# }

# resource "aws_iam_role_policy_attachment" "registry_ecs_service" {
#   role       = "${aws_iam_role.registry_ecs_service.name}"
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
# }

# data "aws_iam_policy_document" "registry_ecs_service" {
#   statement {
#     actions = ["sts:AssumeRole"]

#     principals {
#       type        = "Service"
#       identifiers = ["ecs.amazonaws.com"]
#     }
#   }
# }

resource "aws_cloudwatch_log_group" "registry" {
  name = "jupyterhub-registry"
}

resource "aws_iam_role" "registry_task_execution" {
  name               = "registry-task-execution"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.registry_task_execution.json}"
}

data "aws_iam_policy_document" "registry_task_execution" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "registry_task_execution" {
  role       = "${aws_iam_role.registry_task_execution.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_alb" "registry" {
  name            = "jupyterhub-registry"
  subnets         = ["${data.aws_subnet.private_subnets_with_egress.*.id}"]
  security_groups = ["${aws_security_group.registry_alb.id}"]
}

resource "aws_alb_listener" "registry" {
  load_balancer_arn = "${aws_alb.registry.arn}"
  port              = "${local.registry_alb_port}"
  protocol          = "HTTPS"

  default_action {
    target_group_arn = "${aws_alb_target_group.registry.arn}"
    type             = "forward"
  }

  certificate_arn = "${aws_acm_certificate_validation.registry.certificate_arn}"
}

resource "aws_alb_target_group" "registry" {
  name     = "jupyerhub-registry"
  port     = "${local.registry_target_group_port}"
  protocol = "HTTPS"
  vpc_id   = "${data.aws_vpc.vpc.id}"
  target_type = "ip"
}

resource "aws_acm_certificate" "registry" {
  domain_name       = "${aws_route53_record.registry.name}"
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "registry" {
  certificate_arn = "${aws_acm_certificate.registry.arn}"
}
