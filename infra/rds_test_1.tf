resource "aws_db_instance" "test_1" {
  identifier = "jupyerhub-test-1"

  allocated_storage = 20
  storage_type = "gp2"
  engine = "postgres"
  engine_version = "10.4"
  instance_class = "db.t2.micro"

  name = "jupyterhub_test_1"
  username = "jupyterhub_test_1_master"
  password = "${random_string.aws_db_instance_test_1_password.result}"

  vpc_security_group_ids = ["${aws_security_group.test_1_db.id}"]
  db_subnet_group_name = "${aws_db_subnet_group.test_1.name}"
}

resource "aws_db_subnet_group" "test_1" {
  name       = "jupyerhub-test-1"
  subnet_ids = ["${data.aws_subnet.private_subnets_with_egress.*.id}"]

  tags {
    Name = "jupyerhub-test-1"
  }
}

resource "random_string" "aws_db_instance_test_1_password" {
  length = 128
  special = false
}
