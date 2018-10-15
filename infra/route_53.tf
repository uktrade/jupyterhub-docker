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
}
