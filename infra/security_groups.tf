resource "aws_security_group" "dnsmasq" {
  name        = "jupyterhub-dnsmasq"
  description = "jupyterhub-dnsmasq"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "jupyterhub-dnsmasq"
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

resource "aws_security_group" "logstash_alb" {
  name        = "jupyterhub-logstash-alb"
  description = "jupyterhub-logstash-alb"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "jupyterhub-logstash-alb"
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
  name        = "jupyterhub-logstash-service"
  description = "jupyterhub-logstash-service"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "jupyterhub-logstash-service"
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
  name        = "jupyterhub-registry-alb"
  description = "jupyterhub-registry-alb"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "jupyterhub-registry-alb"
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
  name        = "jupyterhub-registry-service"
  description = "jupyterhub-registry-service"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "jupyterhub-registry-service"
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
  name        = "jupyterhub-admin-alb"
  description = "jupyterhub-admin-alb"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "jupyterhub-admin-alb"
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

resource "aws_security_group" "admin_service" {
  name        = "jupyterhub-admin-service"
  description = "jupyterhub-admin-service"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "jupyterhub-admin-service"
  }
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
  name        = "jupyterhub-admin-db"
  description = "jupyterhub-admin-db"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "jupyterhub-admin-db"
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
  name        = "jupyterhub-test-1-db"
  description = "jupyterhub-test-1-db"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "jupyterhub-test-1-db"
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
  name        = "jupyterhub-alb"
  description = "jupyterhub-alb"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "jupyterhub-alb"
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
  name        = "jupyterhub-db"
  description = "jupyterhub-db"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "jupyterhub-db"
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
  name        = "jupyterhub-service"
  description = "jupyterhub-service"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "jupyterhub"
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
  name        = "jupyterhub-notebooks"
  description = "jupyterhub-notebooks"
  vpc_id      = "${aws_vpc.notebooks.id}"

  tags {
    Name = "jupyterhub-notebooks"
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
