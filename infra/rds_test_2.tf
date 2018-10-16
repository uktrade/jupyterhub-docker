resource "aws_db_instance" "test_2" {
  identifier = "jupyterhub-test-2"

  allocated_storage = 20
  storage_type = "gp2"
  engine = "postgres"
  engine_version = "10.4"
  instance_class = "db.t2.micro"

  name = "jupyterhub_test_2"
  username = "jupyterhub_test_2_master"
  password = "${random_string.aws_db_instance_test_2_password.result}"

  final_snapshot_identifier = "jupyterhub-test-1-final-snapshot"

  vpc_security_group_ids = ["${aws_security_group.test_2_db.id}"]
  db_subnet_group_name = "${aws_db_subnet_group.test_2.name}"
}

resource "aws_db_subnet_group" "test_2" {
  name       = "jupyterhub-test-2"
  subnet_ids = ["${aws_subnet.private_with_egress.*.id}"]

  tags {
    Name = "jupyterhub-test-2"
  }
}

resource "random_string" "aws_db_instance_test_2_password" {
  length = 128
  special = false
}
