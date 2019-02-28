resource "aws_db_instance" "admin" {
  identifier = "jupyterhub-admin"

  allocated_storage = 20
  storage_type = "gp2"
  engine = "postgres"
  engine_version = "10.6"
  instance_class = "db.t2.medium"

  apply_immediately = true

  backup_retention_period = 31
  backup_window = "03:29-03:59"

  name = "jupyterhub_admin"
  username = "jupyterhub_admin_master"
  password = "${random_string.aws_db_instance_admin_password.result}"

  final_snapshot_identifier = "jupyterhub-admin-final-snapshot"

  vpc_security_group_ids = ["${aws_security_group.admin_db.id}"]
  db_subnet_group_name = "${aws_db_subnet_group.admin.name}"
}

resource "aws_db_subnet_group" "admin" {
  name       = "jupyterhub-admin"
  subnet_ids = ["${aws_subnet.private_with_egress.*.id}"]

  tags {
    Name = "jupyterhub-admin"
  }
}

resource "random_string" "aws_db_instance_admin_password" {
  length = 128
  special = false
}
