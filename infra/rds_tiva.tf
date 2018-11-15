resource "aws_db_instance" "tiva" {
  identifier = "jupyterhub-tiva"

  allocated_storage = 100
  storage_type = "gp2"
  engine = "postgres"
  engine_version = "10.4"
  instance_class = "db.t2.medium"

  apply_immediately = true

  name = "jupyterhub_tiva"
  username = "jupyterhub_tiva_master"
  password = "${random_string.aws_db_instance_tiva_password.result}"

  final_snapshot_identifier = "jupyterhub-tiva-final-snapshot"

  vpc_security_group_ids = ["${aws_security_group.tiva_db.id}"]
  db_subnet_group_name = "${aws_db_subnet_group.tiva.name}"
}

resource "aws_db_subnet_group" "tiva" {
  name       = "jupyterhub-tiva"
  subnet_ids = ["${aws_subnet.private_with_egress.*.id}"]

  tags {
    Name = "jupyterhub-tiva"
  }
}

resource "random_string" "aws_db_instance_tiva_password" {
  length = 128
  special = false
}
