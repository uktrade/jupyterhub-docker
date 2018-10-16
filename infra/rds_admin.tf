resource "aws_db_instance" "admin" {
  identifier = "jupyerhub-admin"

  allocated_storage = 20
  storage_type = "gp2"
  engine = "postgres"
  engine_version = "10.4"
  instance_class = "db.t2.micro"

  name = "jupyterhub_admin"
  username = "jupyterhub_admin_master"
  password = "${random_string.aws_db_instance_admin_password.result}"

  vpc_security_group_ids = ["${aws_security_group.admin_db.id}"]
  db_subnet_group_name = "${aws_db_subnet_group.admin.name}"
}

resource "aws_db_subnet_group" "admin" {
  name       = "jupyerhub-admin"
  subnet_ids = ["${data.aws_subnet.private_subnets_with_egress.*.id}"]

  tags {
    Name = "jupyerhub-admin"
  }
}

resource "random_string" "aws_db_instance_admin_password" {
  length = 128
  special = false
}
