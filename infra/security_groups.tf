resource "aws_security_group" "registry_alb" {
  name        = "jupyterhub-registry-alb"
  description = "jupyterhub-registry-alb"
  vpc_id      = "${data.aws_vpc.vpc.id}"

  tags {
    Name = "jupyterhub-registry-alb"
  }
}

resource "aws_security_group_rule" "registry_alb_egress_https_to_service" {
  description = "HTTPS to registry service"

  security_group_id = "${aws_security_group.registry_alb.id}"
  source_security_group_id = "${aws_security_group.registry_service.id}"

  type        = "egress"
  from_port   = "${local.registry_target_group_port}"
  to_port     = "${local.registry_target_group_port}"
  protocol    = "tcp"
}

resource "aws_security_group" "registry_service" {
  name        = "jupyterhub-registry-service"
  description = "jupyterhub-registry-service"
  vpc_id      = "${data.aws_vpc.vpc.id}"

  tags {
    Name = "jupyterhub-registry-service"
  }
}

resource "aws_security_group_rule" "registry_service_ingress_https_from_alb" {
  description = "HTTPS from ALB"

  security_group_id = "${aws_security_group.registry_service.id}"
  source_security_group_id = "${aws_security_group.registry_alb.id}"

  type        = "ingress"
  from_port   = "${local.registry_target_group_port}"
  to_port     = "${local.registry_target_group_port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "registry_service_egress_https_to_everywhere" {
  description = "HTTPS to public internet - needed for quay.io"

  security_group_id = "${aws_security_group.registry_service.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}
