data "aws_route53_zone" "aws_route53_zone" {
  name = "${var.aws_route53_zone}"
}

resource "aws_route53_record" "registry" {
  zone_id = "${data.aws_route53_zone.aws_route53_zone.zone_id}"
  name    = "${var.registry_internal_domain}"
  type    = "A"

  alias {
    name                   = "${aws_alb.registry.dns_name}"
    zone_id                = "${aws_alb.registry.zone_id}"
    evaluate_target_health = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "registry" {
  domain_name       = "${aws_route53_record.registry.name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "registry" {
  certificate_arn = "${aws_acm_certificate.registry.arn}"
}

resource "aws_route53_record" "admin" {
  zone_id = "${data.aws_route53_zone.aws_route53_zone.zone_id}"
  name    = "${var.admin_domain}"
  type    = "A"

  alias {
    name                   = "${aws_alb.admin.dns_name}"
    zone_id                = "${aws_alb.admin.zone_id}"
    evaluate_target_health = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "admin" {
  domain_name       = "${aws_route53_record.admin.name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "admin" {
  certificate_arn = "${aws_acm_certificate.admin.arn}"
}

resource "aws_route53_record" "jupyterhub" {
  zone_id = "${data.aws_route53_zone.aws_route53_zone.zone_id}"
  name    = "${var.jupyterhub_domain}"
  type    = "A"

  alias {
    name                   = "${aws_alb.jupyterhub.dns_name}"
    zone_id                = "${aws_alb.jupyterhub.zone_id}"
    evaluate_target_health = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "jupyterhub" {
  domain_name       = "${aws_route53_record.jupyterhub.name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "jupyterhub" {
  certificate_arn = "${aws_acm_certificate.jupyterhub.arn}"
}
