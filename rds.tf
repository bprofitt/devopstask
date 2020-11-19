resource "random_string" "postgres_password" {
  length = 16
  special = false
}

resource "aws_db_subnet_group" "subnet-mytest-db" {
  name = "subnet_mytest_db"
  subnet_ids = flatten(module.vpc.database_subnets)
  tags = {
    Name        = "mytest-db-subnet-group"
  }
}

resource "aws_db_instance" "myTestDB" {
  identifier           = "mytest-db"
  allocated_storage    = "10"
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "10.6"
  allow_major_version_upgrade = true
  auto_minor_version_upgrade = false
  instance_class       = "db.t2.micro"
  name                 = "myTestDB"
  username             = "myTestDBUser"
  password             = "${random_string.postgres_password.result}"
  db_subnet_group_name = "${aws_db_subnet_group.subnet-mytest-db.name}"
  skip_final_snapshot  = true
  multi_az             = true
  port                 = 7000
  apply_immediately    = true
  vpc_security_group_ids = [aws_security_group.dbsecgroup.id]
  tags = {
    Name        = "mytest-db"
  }
}

resource "aws_ssm_parameter" "mytest-db-connection-string" {
  name        = "/dev/DATABASE_URL"
  description = "The database connectionstring"
  #type        = "SecureString"
  type        = "String"
  #value       = "Server=${aws_db_instance.myTestDB.address};Database=${aws_db_instance.myTestDB.name};UserId=myTestDBUser;Password=${random_string.postgres_password.result}"
  # DATABASE_URL=postgres://USERNAME:PASSWORD@HOST:PORT/DB_NAME
  value       = "postgres://myTestDBUser:${random_string.postgres_password.result}@${aws_db_instance.myTestDB.address}:7000/${aws_db_instance.myTestDB.name}"
  tags = {
    Name        = "mytest-db-connection-string"
  }
}