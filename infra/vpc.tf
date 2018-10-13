data "aws_subnet" "private_subnets_with_egress" {
  count = "${length(var.private_subnets_with_egress)}"
  id    = "${var.private_subnets_with_egress[count.index]}"
}

data "aws_vpc" "vpc" {
  id = "${data.aws_subnet.private_subnets_with_egress.*.vpc_id[0]}"
}
