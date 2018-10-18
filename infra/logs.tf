resource "aws_vpc_endpoint" "logs" {
  vpc_id            = "${aws_vpc.main.id}"
  service_name      = "com.amazonaws.${data.aws_region.aws_region.name}.logs"
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  security_group_ids = [
    "${aws_security_group.logs.id}"
  ]
}

resource "aws_vpc_endpoint_subnet_association" "logs" {
  count           = "${length(var.aws_availability_zones)}"
  vpc_endpoint_id = "${aws_vpc_endpoint.logs.id}"
  subnet_id       = "${aws_subnet.private_without_egress.*.id[count.index]}"
}
