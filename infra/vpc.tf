resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr}"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name = "jupyterhub"
  }
}

resource "aws_subnet" "public" {
  count = "${length(var.aws_availability_zones)}"
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "${cidrsubnet(aws_vpc.main.cidr_block, 4, count.index)}"

  availability_zone = "${var.aws_availability_zones[count.index]}"

  tags {
    Name = "jupyterhub-public-${var.aws_availability_zones_short[count.index]}"
  }
}

resource "aws_subnet" "private_with_egress" {
  count      = "${length(var.aws_availability_zones)}"
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "${cidrsubnet(aws_vpc.main.cidr_block, 4, length(var.aws_availability_zones) + count.index)}"

  availability_zone = "${var.aws_availability_zones[count.index]}"

  tags {
    Name = "jupyterhub-private-with-egress-${var.aws_availability_zones_short[count.index]}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "jupyterhub-public"
  }
}

resource "aws_route_table_association" "jupyterhub_public" {
  count          = "${length(var.aws_availability_zones)}"
  subnet_id      = "${aws_subnet.public.*.id[count.index]}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route" "public_internet_gateway_ipv4" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.main.id}"
}

resource "aws_route" "public_internet_gateway_ipv6" {
  route_table_id              = "${aws_route_table.public.id}"
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = "${aws_internet_gateway.main.id}"
}

resource "aws_route_table" "private_with_egress" {
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "jupyterhub-private-with-egress"
  }
}

resource "aws_route_table_association" "jupyterhub_private_with_egress" {
  count          = "${length(var.aws_availability_zones)}"
  subnet_id      = "${aws_subnet.private_with_egress.*.id[count.index]}"
  route_table_id = "${aws_route_table.private_with_egress.id}"
}

resource "aws_route" "private_with_egress_nat_gateway_ipv4" {
  route_table_id         = "${aws_route_table.private_with_egress.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.main.id}"
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "jupyterhub"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = "${aws_eip.nat_gateway.id}"
  subnet_id     = "${aws_subnet.public.*.id[0]}"

  tags {
    Name = "jupyterhub"
  }
}

resource "aws_eip" "nat_gateway" {
  vpc = true
}
