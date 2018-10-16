resource "aws_security_group" "registry_alb" {
  name        = "jupyterhub-registry-alb"
  description = "jupyterhub-registry-alb"
  vpc_id      = "${aws_vpc.main.id}"

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
  vpc_id      = "${aws_vpc.main.id}"

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

resource "aws_security_group" "admin_alb" {
  name        = "jupyterhub-admin-alb"
  description = "jupyterhub-admin-alb"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "jupyterhub-admin-alb"
  }
}

resource "aws_security_group_rule" "admin_alb_ingress_https" {
  description = "HTTPS from whitelist"

  security_group_id = "${aws_security_group.admin_alb.id}"
  cidr_blocks       = ["${var.ip_whitelist}"]

  type       = "ingress"
  from_port  = "443"
  to_port    = "443"
  protocol   = "tcp"
}

resource "aws_security_group_rule" "admin_alb_ingress_icmp_3" {
  description = "Host unreachable for MTU discovery from whitelist"

  security_group_id = "${aws_security_group.admin_alb.id}"
  cidr_blocks       = ["${var.ip_whitelist}"]

  type      = "ingress"
  from_port = 3
  to_port   = 0
  protocol  = "icmp"
}

resource "aws_security_group_rule" "admin_alb_egress_https_to_service" {
  description = "HTTPS to admin service"

  security_group_id = "${aws_security_group.admin_alb.id}"
  source_security_group_id = "${aws_security_group.admin_service.id}"

  type        = "egress"
  from_port   = "${local.admin_target_group_port}"
  to_port     = "${local.admin_target_group_port}"
  protocol    = "tcp"
}

resource "aws_security_group" "admin_service" {
  name        = "jupyterhub-admin-service"
  description = "jupyterhub-admin-service"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "jupyterhub-admin-service"
  }
}

resource "aws_security_group_rule" "admin_service_ingress_https_from_alb" {
  description = "HTTPS from ALB"

  security_group_id = "${aws_security_group.admin_service.id}"
  source_security_group_id = "${aws_security_group.admin_alb.id}"

  type        = "ingress"
  from_port   = "${local.admin_target_group_port}"
  to_port     = "${local.admin_target_group_port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_https_to_everywhere_ipv4" {
  description = "HTTPS to public internet"

  security_group_id = "${aws_security_group.admin_service.id}"
  cidr_blocks       = ["0.0.0.0/0"]

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_https_to_everywhere_ipv6" {
  description = "HTTPS to public internet"

  security_group_id = "${aws_security_group.admin_service.id}"
  ipv6_cidr_blocks  = ["::/0"]

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_postgres_to_admin_db" {
  description = "Postgres to admin database"

  security_group_id = "${aws_security_group.admin_service.id}"
  source_security_group_id = "${aws_security_group.admin_db.id}"

  type        = "egress"
  from_port   = "${aws_db_instance.admin.port}"
  to_port     = "${aws_db_instance.admin.port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_postgres_to_test_1_db" {
  description = "Postgres to test 1 database"

  security_group_id = "${aws_security_group.admin_service.id}"
  source_security_group_id = "${aws_security_group.test_1_db.id}"

  type        = "egress"
  from_port   = "${aws_db_instance.test_1.port}"
  to_port     = "${aws_db_instance.test_1.port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_postgres_to_test_2_db" {
  description = "Postgres to test 2 database"

  security_group_id = "${aws_security_group.admin_service.id}"
  source_security_group_id = "${aws_security_group.test_2_db.id}"

  type        = "egress"
  from_port   = "${aws_db_instance.test_2.port}"
  to_port     = "${aws_db_instance.test_2.port}"
  protocol    = "tcp"
}

resource "aws_security_group" "admin_db" {
  name        = "jupyterhub-admin-db"
  description = "jupyterhub-admin-db"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "jupyterhub-admin-db"
  }
}

resource "aws_security_group_rule" "admin_db_ingress_postgres_from_admin_service" {
  description = "Postgres from admin service"

  security_group_id = "${aws_security_group.admin_db.id}"
  source_security_group_id = "${aws_security_group.admin_service.id}"

  type        = "ingress"
  from_port   = "${aws_db_instance.admin.port}"
  to_port     = "${aws_db_instance.admin.port}"
  protocol    = "tcp"
}

resource "aws_security_group" "test_1_db" {
  name        = "jupyterhub-test-1-db"
  description = "jupyterhub-test-1-db"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "jupyterhub-test-1-db"
  }
}

resource "aws_security_group_rule" "test_1_db_ingress_postgres_from_admin_service" {
  description = "Postgres from admin service"

  security_group_id = "${aws_security_group.test_1_db.id}"
  source_security_group_id = "${aws_security_group.admin_service.id}"

  type        = "ingress"
  from_port   = "${aws_db_instance.test_1.port}"
  to_port     = "${aws_db_instance.test_1.port}"
  protocol    = "tcp"
}

resource "aws_security_group" "test_2_db" {
  name        = "jupyterhub-test-2-db"
  description = "jupyterhub-test-2-db"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "jupyterhub-test-2-db"
  }
}

resource "aws_security_group_rule" "test_2_db_ingress_postgres_from_admin_db" {
  description = "Postgres from admin service"

  security_group_id = "${aws_security_group.test_2_db.id}"
  source_security_group_id = "${aws_security_group.admin_service.id}"

  type        = "ingress"
  from_port   = "${aws_db_instance.test_2.port}"
  to_port     = "${aws_db_instance.test_2.port}"
  protocol    = "tcp"
}
