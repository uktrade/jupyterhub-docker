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

resource "aws_security_group_rule" "registry_alb_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id = "${aws_security_group.registry_alb.id}"
  source_security_group_id = "${aws_security_group.cloudwatch.id}"

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
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
  cidr_blocks       = ["${var.ip_whitelist}", "${aws_eip.nat_gateway.public_ip}/32"]

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

resource "aws_security_group_rule" "admin_alb_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id = "${aws_security_group.admin_alb.id}"
  source_security_group_id = "${aws_security_group.cloudwatch.id}"

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
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

resource "aws_security_group_rule" "admin_redis_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id = "${aws_security_group.admin_redis.id}"
  source_security_group_id = "${aws_security_group.cloudwatch.id}"

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
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

resource "aws_security_group_rule" "admin_service_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id = "${aws_security_group.admin_service.id}"
  source_security_group_id = "${aws_security_group.cloudwatch.id}"

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
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

resource "aws_security_group_rule" "admin_service_egress_https_to_everywhere" {
  description = "egress-https-to-everywhere"

  security_group_id = "${aws_security_group.admin_service.id}"
  cidr_blocks       = ["0.0.0.0/0"]

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "admin_service_egress_http_to_notebooks" {
  description = "egress-https-to-everywhere"

  security_group_id = "${aws_security_group.admin_service.id}"
  source_security_group_id = "${aws_security_group.notebooks.id}"

  type        = "egress"
  from_port   = "${local.notebook_container_port}"
  to_port     = "${local.notebook_container_port}"
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

resource "aws_security_group_rule" "admin_sdb_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id = "${aws_security_group.admin_db.id}"
  source_security_group_id = "${aws_security_group.cloudwatch.id}"

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
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

resource "aws_security_group_rule" "notebooks_ingress_https_from_admin" {
  description = "ingress-https-from-jupytehub"

  security_group_id = "${aws_security_group.notebooks.id}"
  source_security_group_id = "${aws_security_group.admin_service.id}"

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

resource "aws_security_group" "cloudwatch" {
  name        = "${var.prefix}-cloudwatch"
  description = "${var.prefix}-cloudwatch"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-cloudwatch"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "cloudwatch_ingress_https_from_all" {
  description = "ingress-https-from-everywhere"

  security_group_id = "${aws_security_group.cloudwatch.id}"
  cidr_blocks = ["0.0.0.0/0"]

  type        = "ingress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
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

resource "aws_security_group" "healthcheck_alb" {
  name        = "${var.prefix}-healthcheck-alb"
  description = "${var.prefix}-healthcheck-alb"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-healthcheck-alb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "healthcheck_alb_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id = "${aws_security_group.healthcheck_alb.id}"
  source_security_group_id = "${aws_security_group.cloudwatch.id}"

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "healthcheck_alb_ingress_https_from_all" {
  description = "ingress-https-from-all"

  security_group_id = "${aws_security_group.healthcheck_alb.id}"
  cidr_blocks       = ["0.0.0.0/0"]

  type       = "ingress"
  from_port  = "443"
  to_port    = "443"
  protocol   = "tcp"
}

resource "aws_security_group_rule" "healthcheck_alb_egress_https_to_healthcheck_service" {
  description = "egress-https-to-healthcheck-service"

  security_group_id = "${aws_security_group.healthcheck_alb.id}"
  source_security_group_id = "${aws_security_group.healthcheck_service.id}"
 
  type        = "egress"
  from_port   = "${local.healthcheck_container_port}"
  to_port     = "${local.healthcheck_container_port}"
  protocol    = "tcp"
}

resource "aws_security_group" "healthcheck_service" {
  name        = "${var.prefix}-healthcheck_service"
  description = "${var.prefix}-healthcheck_service"
  vpc_id      = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-healthcheck_service"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "healthcheck_service_egress_https_to_cloudwatch" {
  description = "egress-https-to-cloudwatch"

  security_group_id = "${aws_security_group.healthcheck_service.id}"
  source_security_group_id = "${aws_security_group.cloudwatch.id}"

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "healthcheck_service_ingress_https_from_healthcheck_alb" {
  description = "ingress-https-from-healthcheck-alb"

  security_group_id = "${aws_security_group.healthcheck_service.id}"
  source_security_group_id = "${aws_security_group.healthcheck_alb.id}"

  type        = "ingress"
  from_port   = "${local.healthcheck_container_port}"
  to_port     = "${local.healthcheck_container_port}"
  protocol    = "tcp"
}

resource "aws_security_group_rule" "healthcheck_service_egress_https_to_everywhere" {
  description = "ingress-https-from-healthcheck-alb"

  security_group_id = "${aws_security_group.healthcheck_service.id}"
  cidr_blocks = ["0.0.0.0/0"]

  type        = "egress"
  from_port   = "443"
  to_port     = "443"
  protocol    = "tcp"
}
