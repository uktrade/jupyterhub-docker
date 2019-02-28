resource "aws_db_instance" "test_1" {
  identifier = "jupyterhub-test-1"

  allocated_storage = 20
  storage_type = "gp2"
  engine = "postgres"
  engine_version = "10.6"
  instance_class = "db.t2.medium"

  apply_immediately = true

  name = "jupyterhub_test_1"
  username = "jupyterhub_test_1_master"
  password = "${random_string.aws_db_instance_test_1_password.result}"

  final_snapshot_identifier = "jupyterhub-test-1-final-snapshot"

  vpc_security_group_ids = ["${aws_security_group.test_1_db.id}"]
  db_subnet_group_name = "${aws_db_subnet_group.test_1.name}"
}

resource "aws_db_subnet_group" "test_1" {
  name       = "jupyterhub-test-1"
  subnet_ids = ["${aws_subnet.private_with_egress.*.id}"]

  tags {
    Name = "jupyterhub-test-1"
  }
}

resource "random_string" "aws_db_instance_test_1_password" {
  length = 128
  special = false
}
