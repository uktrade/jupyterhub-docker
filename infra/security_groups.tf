resource "aws_security_group" "dnsmasq" {
  name        = "${var.prefix}-dnsmasq"
  description = "${var.prefix}-dnsmasq"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-dnsmasq"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "dnsmasq_egress_https" {
  description = "egress-dns-tcp"

  security_group_id = "${aws_security_group.dnsmasq.id}"
  cidr_blocks = ["0.0.0.0/0"]

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "dnsmasq_ingress_dns_tcp_notebooks" {
  description = "ingress-dns-tcp"

  security_group_id = "${aws_security_group.dnsmasq.id}"
  source_security_group_id = "${aws_security_group.notebooks.id}"

  type        = "ingress"
  from_port   = "53"
  to_port     = "53"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "dnsmasq_ingress_dns_udp_notebooks" {
  description = "ingress-dns-udp"

  security_group_id = "${aws_security_group.dnsmasq.id}"
  source_security_group_id = "${aws_security_group.notebooks.id}"

  type        = "ingress"
  from_port   = "53"
  to_port     = "53"
  protocol    = "udp"
}

resource "aws_security_group" "sentryproxy_service" {
  name        = "${var.prefix}-sentryproxy"
  description = "${var.prefix}-sentryproxy"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-sentryproxy"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "sentryproxy_egress_https" {
  description = "egress-https"

  security_group_id = "${aws_security_group.sentryproxy_service.id}"
  cidr_blocks = ["0.0.0.0/0"]

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "sentryproxy_ingress_http_notebooks" {
  description = "ingress-http"

  security_group_id = "${aws_security_group.sentryproxy_service.id}"
  source_security_group_id = "${aws_security_group.notebooks.id}"

  type        = "ingress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group" "logstash_alb" {
  name        = "${var.prefix}-logstash-alb"
  description = "${var.prefix}-logstash-alb"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-logstash-alb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "logstash_alb_ingress_https_from_notebooks" {
  description = "ingress-https-from-notebooks"

  security_group_id = "${aws_security_group.logstash_alb.id}"
  source_security_group_id = "${aws_security_group.notebooks.id}"

  type        = "ingress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "logstash_alb_egress_https_to_service" {
  description = "egress-https-to-service"

  security_group_id = "${aws_security_group.logstash_alb.id}"
  source_security_group_id = "${aws_security_group.logstash_service.id}"

  type        = "egress"
  from_port   = "${local.logstash_container_port}"
  to_port     = "${local.logstash_container_port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "logstash_alb_egress_http_api_to_service" {
  description = "egress-https-to-service"

  security_group_id = "${aws_security_group.logstash_alb.id}"
  source_security_group_id = "${aws_security_group.logstash_service.id}"

  type        = "egress"
  from_port   = "${local.logstash_container_api_port}"
  to_port     = "${local.logstash_container_api_port}"
  protocol    = "tcp"
}

resource "aws_security_group" "logstash_service" {
  name        = "${var.prefix}-logstash-service"
  description = "${var.prefix}-logstash-service"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-logstash-service"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "logstash_service_ingress_https_from_alb" {
  description = "ingress-https-from-alb"

  security_group_id = "${aws_security_group.logstash_service.id}"
  source_security_group_id = "${aws_security_group.logstash_alb.id}"

  type        = "ingress"
  from_port   = "${local.logstash_container_port}"
  to_port     = "${local.logstash_container_port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "logstash_service_ingress_http_api_from_alb" {
  description = "egress-https-to-service"

  security_group_id = "${aws_security_group.logstash_service.id}"
  source_security_group_id = "${aws_security_group.logstash_alb.id}"

  type        = "ingress"
  from_port   = "${local.logstash_container_api_port}"
  to_port     = "${local.logstash_container_api_port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "logstash_service_egress_https_to_everywhere" {
  description = "egress-https-to-everywhere"

  security_group_id = "${aws_security_group.logstash_service.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group" "registry_alb" {
  name        = "${var.prefix}-registry-alb"
  description = "${var.prefix}-registry-alb"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-registry-alb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "registry_alb_ingress_https_from_notebooks" {
  description = "ingress-https-from-notebooks"

  security_group_id = "${aws_security_group.registry_alb.id}"
  source_security_group_id = "${aws_security_group.notebooks.id}"

  type        = "ingress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "registry_alb_egress_https_to_service" {
  description = "egress-https-to-service"

  security_group_id = "${aws_security_group.registry_alb.id}"
  source_security_group_id = "${aws_security_group.registry_service.id}"

  type        = "egress"
  from_port   = "${local.registry_container_port}"
  to_port     = "${local.registry_container_port}"
  protocol    = "tcp"
}

resource "aws_security_group" "registry_service" {
  name        = "${var.prefix}-registry-service"
  description = "${var.prefix}-registry-service"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-registry-service"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "registry_service_ingress_https_from_alb" {
  description = "ingress-https-from-alb"

  security_group_id = "${aws_security_group.registry_service.id}"
  source_security_group_id = "${aws_security_group.registry_alb.id}"

  type        = "ingress"
  from_port   = "${local.registry_container_port}"
  to_port     = "${local.registry_container_port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "registry_service_egress_https_to_everywhere" {
  description = "egress-https-to-everywhere"

  security_group_id = "${aws_security_group.registry_service.id}"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group" "admin_alb" {
  name        = "${var.prefix}-admin-alb"
  description = "${var.prefix}-admin-alb"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-admin-alb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "admin_alb_ingress_https_from_whitelist" {
  description = "ingress-https-from-whitelist"

  security_group_id = "${aws_security_group.admin_alb.id}"
  cidr_blocks       = ["${var.ip_whitelist}"]

  type       = "ingress"
  from_port  = "443"
  to_port    = "443"
  protocol   = "tcp"
}

resource "aws_security_group_rule" "admin_alb_ingress_icmp_host_unreachable_for_mtu_discovery_from_whitelist" {
  description = "ingress-icmp-host-unreachable-for-mtu-discovery-from-whitelist"

  security_group_id = "${aws_security_group.admin_alb.id}"
  cidr_blocks       = ["${var.ip_whitelist}"]

  type      = "ingress"
  from_port = 3
  to_port   = 0
  protocol  = "icmp"
}

resource "aws_security_group_rule" "admin_alb_egress_https_to_admin_service" {
  description = "egress-https-to-admin-service"

  security_group_id = "${aws_security_group.admin_alb.id}"
  source_security_group_id = "${aws_security_group.admin_service.id}"

  type        = "egress"
  from_port   = "${local.admin_container_port}"
  to_port     = "${local.admin_container_port}"
  protocol    = "tcp"
}

resource "aws_security_group" "admin_redis" {
  name        = "${var.prefix}-admin-redis"
  description = "${var.prefix}-admin-redis"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-admin-redis"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "admin_redis_ingress_from_admin_service" {
  description = "ingress-redis-from-admin-service"

  security_group_id = "${aws_security_group.admin_redis.id}"
  source_security_group_id = "${aws_security_group.admin_service.id}"

  type        = "ingress"
  from_port   = "6379"
  to_port     = "6379"
  protocol    = "tcp"
}

resource "aws_security_group" "admin_service" {
  name        = "${var.prefix}-admin-service"
  description = "${var.prefix}-admin-service"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-admin-service"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "admin_service_egress_to_admin_service" {
  description = "egress-redis-to-admin-redis"

  security_group_id = "${aws_security_group.admin_service.id}"
  source_security_group_id = "${aws_security_group.admin_redis.id}"

  type        = "egress"
  from_port   = "6379"
  to_port     = "6379"
  protocol    = "tcp"
}


resource "aws_security_group_rule" "admin_service_ingress_https_from_admin_alb" {
  description = "ingress-https-from-admin-alb"

  security_group_id = "${aws_security_group.admin_service.id}"
  source_security_group_id = "${aws_security_group.admin_alb.id}"

  type        = "ingress"
  from_port   = "${local.admin_container_port}"
  to_port     = "${local.admin_container_port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "admin_service_ingress_https_from_jupyterhub_service" {
  description = "ingress-https-from-jupyterhub-service"

  security_group_id = "${aws_security_group.admin_service.id}"
  source_security_group_id = "${aws_security_group.jupyterhub_service.id}"

  type        = "ingress"
  from_port   = "${local.admin_container_port}"
  to_port     = "${local.admin_container_port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_https_to_everywhere" {
  description = "egress-https-to-everywhere"

  security_group_id = "${aws_security_group.admin_service.id}"
  cidr_blocks       = ["0.0.0.0/0"]

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_postgres_to_admin_db" {
  description = "egress-postgres-to-admin-db"

  security_group_id = "${aws_security_group.admin_service.id}"
  source_security_group_id = "${aws_security_group.admin_db.id}"

  type        = "egress"
  from_port   = "${aws_db_instance.admin.port}"
  to_port     = "${aws_db_instance.admin.port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_postgres_to_tiva_db" {
  description = "egress-postgres-to-test-1-db"

  security_group_id = "${aws_security_group.admin_service.id}"
  source_security_group_id = "${aws_security_group.tiva_db.id}"

  type        = "egress"
  from_port   = "${aws_db_instance.tiva.port}"
  to_port     = "${aws_db_instance.tiva.port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_postgres_to_test_1_db" {
  description = "egress-postgres-to-test-1-db"

  security_group_id = "${aws_security_group.admin_service.id}"
  source_security_group_id = "${aws_security_group.test_1_db.id}"

  type        = "egress"
  from_port   = "${aws_db_instance.test_1.port}"
  to_port     = "${aws_db_instance.test_1.port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_postgres_to_test_2_db" {
  description = "egress-postgres-to-test-2-db"

  security_group_id = "${aws_security_group.admin_service.id}"
  source_security_group_id = "${aws_security_group.test_2_db.id}"

  type        = "egress"
  from_port   = "${aws_db_instance.test_2.port}"
  to_port     = "${aws_db_instance.test_2.port}"
  protocol    = "tcp"
}

resource "aws_security_group" "admin_db" {
  name        = "${var.prefix}-admin-db"
  description = "${var.prefix}-admin-db"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-admin-db"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "admin_db_ingress_postgres_from_admin_service" {
  description = "ingress-postgres-from-admin-service"

  security_group_id = "${aws_security_group.admin_db.id}"
  source_security_group_id = "${aws_security_group.admin_service.id}"

  type        = "ingress"
  from_port   = "${aws_db_instance.admin.port}"
  to_port     = "${aws_db_instance.admin.port}"
  protocol    = "tcp"
}

resource "aws_security_group" "tiva_db" {
  name        = "jupyterhub-tiva-db"
  description = "jupyterhub-tiva-db"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "jupyterhub-tiva-db"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "tiva_db_ingress_postgres_from_admin_service" {
  description = "ingress-postgres-from-admin-service"

  security_group_id = "${aws_security_group.tiva_db.id}"
  source_security_group_id = "${aws_security_group.admin_service.id}"

  type        = "ingress"
  from_port   = "${aws_db_instance.tiva.port}"
  to_port     = "${aws_db_instance.tiva.port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "tiva_db_ingress_postgres_from_notebooks" {
  description = "ingress-postgres-from-notebooks"

  security_group_id        = "${aws_security_group.tiva_db.id}"
  source_security_group_id = "${aws_security_group.notebooks.id}"

  type      = "ingress"
  from_port = "${aws_db_instance.tiva.port}"
  to_port   = "${aws_db_instance.tiva.port}"
  protocol    = "tcp"
}

resource "aws_security_group" "test_1_db" {
  name        = "${var.prefix}-test-1-db"
  description = "${var.prefix}-test-1-db"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-test-1-db"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "test_1_db_ingress_postgres_from_admin_service" {
  description = "ingress-postgres-from-admin-service"

  security_group_id = "${aws_security_group.test_1_db.id}"
  source_security_group_id = "${aws_security_group.admin_service.id}"

  type        = "ingress"
  from_port   = "${aws_db_instance.test_1.port}"
  to_port     = "${aws_db_instance.test_1.port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "test_1_db_ingress_postgres_from_notebooks" {
  description = "ingress-postgres-from-notebooks"

  security_group_id        = "${aws_security_group.test_1_db.id}"
  source_security_group_id = "${aws_security_group.notebooks.id}"

  type      = "ingress"
  from_port = "${aws_db_instance.test_1.port}"
  to_port   = "${aws_db_instance.test_1.port}"
  protocol    = "tcp"
}

resource "aws_security_group" "test_2_db" {
  name        = "jupyterhub-test-2-db"
  description = "jupyterhub-test-2-db"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "jupyterhub-test-2-db"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "test_2_db_ingress_postgres_from_admin_db" {
  description = "ingress-postgres-from-admin-db"

  security_group_id = "${aws_security_group.test_2_db.id}"
  source_security_group_id = "${aws_security_group.admin_service.id}"

  type        = "ingress"
  from_port   = "${aws_db_instance.test_2.port}"
  to_port     = "${aws_db_instance.test_2.port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "test_2_db_ingress_postgres_from_notebooks" {
  description = "ingress-postgres-from-notebooks"

  security_group_id        = "${aws_security_group.test_2_db.id}"
  source_security_group_id = "${aws_security_group.notebooks.id}"

  type      = "ingress"
  from_port = "${aws_db_instance.test_2.port}"
  to_port   = "${aws_db_instance.test_2.port}"
  protocol  = "tcp"
}

resource "aws_security_group" "jupyterhub_alb" {
  name        = "${var.prefix}-alb"
  description = "${var.prefix}-alb"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-alb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "jupyterhub_alb_ingress_https_from_whitelist" {
  description = "ingress-https-from-whitelist"

  security_group_id = "${aws_security_group.jupyterhub_alb.id}"
  cidr_blocks       = ["${var.ip_whitelist}"]

  type      = "ingress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "jupyterhub_alb_ingress_icmp_host_unreachable_for_mtu_discovery" {
  description = "ingress-icmp-host-unreachable-for-mtu-discovery-from-whitelist"

  security_group_id = "${aws_security_group.jupyterhub_alb.id}"
  cidr_blocks       = ["${var.ip_whitelist}"]

  type      = "ingress"
  from_port = 3
  to_port   = 0
  protocol  = "icmp"
}

resource "aws_security_group_rule" "jupyterhub_alb_egress_https_to_jupyterhub_service" {
  description = "egress-https-to-jupyterhub_service"

  security_group_id = "${aws_security_group.jupyterhub_alb.id}"
  source_security_group_id = "${aws_security_group.jupyterhub_service.id}"

  type      = "egress"
  from_port = "${local.jupyterhub_container_port}"
  to_port   = "${local.jupyterhub_container_port}"
  protocol  = "tcp"
}

resource "aws_security_group" "jupyterhub_db" {
  name        = "${var.prefix}-db"
  description = "${var.prefix}-db"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-db"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "jupyterhub_db_ingress_postgres_from_jupyterhub_service" {
  description = "ingress-postgres-from-jupyterhub-service"

  security_group_id        = "${aws_security_group.jupyterhub_db.id}"
  source_security_group_id = "${aws_security_group.jupyterhub_service.id}"

  type      = "ingress"
  from_port = "${aws_db_instance.jupyterhub.port}"
  to_port   = "${aws_db_instance.jupyterhub.port}"
  protocol    = "tcp"
}

resource "aws_security_group" "jupyterhub_service" {
  name        = "${var.prefix}-service"
  description = "${var.prefix}-service"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "jupyterhub_egress_postgres_to_jupyterhub_db" {
  description = "egress-postgres-to-jupyterhub_db"

  security_group_id        = "${aws_security_group.jupyterhub_service.id}"
  source_security_group_id = "${aws_security_group.jupyterhub_db.id}"

  type      = "egress"
  from_port = "${aws_db_instance.jupyterhub.port}"
  to_port   = "${aws_db_instance.jupyterhub.port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "jupyterhub_service_egress_https_to_jupyterhub_admin" {
  description = "egress-https-to-jupyterhub_admin"

  security_group_id = "${aws_security_group.jupyterhub_service.id}"
  source_security_group_id = "${aws_security_group.admin_service.id}"

  type        = "egress"
  from_port   = "${local.admin_container_port}"
  to_port     = "${local.admin_container_port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "jupyterhub_service_egress_https_to_everywhere" {
  description = "egress-https-to-everywhere"

  security_group_id = "${aws_security_group.jupyterhub_service.id}"
  cidr_blocks       = ["0.0.0.0/0"]

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "jupyterhub_egress_https_to_notebooks" {
  description = "egress-https-to-notebooks"

  security_group_id = "${aws_security_group.jupyterhub_service.id}"
  source_security_group_id = "${aws_security_group.notebooks.id}"

  type      = "egress"
  from_port = "${local.notebook_container_port}"
  to_port   = "${local.notebook_container_port}"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "jupyterhub_ingress_https_from_notebooks" {
  description = "ingress-https-from-notebooks"

  security_group_id = "${aws_security_group.jupyterhub_service.id}"
  source_security_group_id = "${aws_security_group.notebooks.id}"

  type      = "ingress"
  from_port = "${local.jupyterhub_container_port}"
  to_port   = "${local.jupyterhub_container_port}"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "jupyterhub_service_ingress_https_from_jupyterhub_alb" {
  description = "ingress-https-from-jupyterhub-alb"

  security_group_id = "${aws_security_group.jupyterhub_service.id}"
  source_security_group_id = "${aws_security_group.jupyterhub_alb.id}"

  type      = "ingress"
  from_port = "${local.jupyterhub_container_port}"
  to_port   = "${local.jupyterhub_container_port}"
  protocol  = "tcp"
}

resource "aws_security_group" "notebooks" {
  name        = "${var.prefix}-notebooks"
  description = "${var.prefix}-notebooks"
  vpc_id      = "${aws_vpc.notebooks.id}"

  tags {
    Name = "${var.prefix}-notebooks"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "notebooks_ingress_https_from_jupytehub" {
  description = "ingress-https-from-jupytehub"

  security_group_id = "${aws_security_group.notebooks.id}"
  source_security_group_id = "${aws_security_group.jupyterhub_service.id}"

  type      = "ingress"
  from_port = "${local.notebook_container_port}"
  to_port   = "${local.notebook_container_port}"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "notebooks_egress_https_to_everywhere" {
  description = "egress-https-to-everywhere"

  security_group_id = "${aws_security_group.notebooks.id}"
  cidr_blocks       = ["0.0.0.0/0"]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "notebooks_egress_https_to_jupyterhub_service" {
  description = "egress-https-to-jupyterhub-service"

  security_group_id        = "${aws_security_group.notebooks.id}"
  source_security_group_id = "${aws_security_group.jupyterhub_service.id}"

  type      = "egress"
  from_port = "${local.jupyterhub_container_port}"
  to_port   = "${local.jupyterhub_container_port}"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "notebooks_egress_postgres_to_tiva" {
  description = "egress-postgres-to-test-1"

  security_group_id        = "${aws_security_group.notebooks.id}"
  source_security_group_id = "${aws_security_group.tiva_db.id}"

  type      = "egress"
  from_port = "${aws_db_instance.tiva.port}"
  to_port   = "${aws_db_instance.tiva.port}"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "notebooks_egress_postgres_to_test_1" {
  description = "egress-postgres-to-test-1"

  security_group_id        = "${aws_security_group.notebooks.id}"
  source_security_group_id = "${aws_security_group.test_1_db.id}"

  type      = "egress"
  from_port = "${aws_db_instance.test_1.port}"
  to_port   = "${aws_db_instance.test_1.port}"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "notebooks_egress_postgres_to_test_2" {
  description = "egress-postgres-to-test-2"

  security_group_id        = "${aws_security_group.notebooks.id}"
  source_security_group_id = "${aws_security_group.test_2_db.id}"

  type      = "egress"
  from_port = "${aws_db_instance.test_2.port}"
  to_port   = "${aws_db_instance.test_2.port}"
  protocol  = "tcp"
}

resource "aws_security_group_rule" "notebooks_egress_dns_tcp" {
  description = "egress-dns-tcp"

  security_group_id = "${aws_security_group.notebooks.id}"
  source_security_group_id = "${aws_security_group.dnsmasq.id}"

  type        = "egress"
  from_port   = "53"
  to_port     = "53"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "notebooks_egress_dns_udp" {
  description = "egress-dns-udp"

  security_group_id = "${aws_security_group.notebooks.id}"
  source_security_group_id = "${aws_security_group.dnsmasq.id}"

  type        = "egress"
  from_port   = "53"
  to_port     = "53"
  protocol    = "udp"
}

resource "aws_security_group" "mirrors_sync" {
  name        = "${var.prefix}-mirrors-sync"
  description = "${var.prefix}-mirrors-sync"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-mirrors-sync"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "mirrors_sync_egress_https_to_everywhere" {
  description = "egress-https-to-everywhere"

  security_group_id = "${aws_security_group.mirrors_sync.id}"
  cidr_blocks       = ["0.0.0.0/0"]

  type      = "egress"
  from_port = "443"
  to_port   = "443"
  protocol  = "tcp"
}
