# RDS MySQL creation in Stockholm Region
resource "aws_db_instance" "RDS" {
    allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = var.username
  password             = var.pwd
  db_subnet_group_name = aws_db_subnet_group.primary_group.id
  parameter_group_name = "default.mysql8.0"
    
    # Skip final snapshot
  skip_final_snapshot  = true
  
  #   Backup Options
  backup_retention_period = 7
  backup_window = "02:00-03:00"

  # Monitoring
  monitoring_interval      = 60 
  monitoring_role_arn      = aws_iam_role.rds_monitoring.arn
  
  # Maintenance window as per UTC
  maintenance_window = "sun:04:00-sun:05:00"  

  # Deletion protection
  deletion_protection = false

  
}

#Creating IAM Role
resource "aws_iam_role" "rds_monitoring" {
  name = "rds-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })
}

#Attaching IAM to RDS
resource "aws_iam_role_policy_attachment" "rds_monitoring_attach" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  depends_on = [ aws_iam_role.rds_monitoring ]
}


# Creating subnet group from the default subnets

resource "aws_db_subnet_group" "primary_group" {
    name = "primarysubnetgroup"
    subnet_ids = ["subnet-055a77b3a69f8cd1a", "subnet-0fa001c6d7a2727b0"]

    tags = {
      Name = "Primary Subnet Group"
    }


}


# Creating subnet group from the default subnets in region 2

resource "aws_db_subnet_group" "secondary_group" {
    name = "secondarysubnetgroup"
    subnet_ids = ["subnet-0f4b3e92022af8e1d", "subnet-024003abf3e8995db"]
    provider = aws.secondary

    tags = {
      Name = "Secondary Subnet Group"
    }


}

#Creating Read Replica
resource "aws_db_instance" "read_replica" {
  identifier          = "book-rds-replica"
  replicate_source_db = aws_db_instance.RDS.arn
  instance_class      = "db.t3.micro"
  provider = aws.secondary

  # Network configuration in secondary region
  db_subnet_group_name = aws_db_subnet_group.secondary_group.name
  publicly_accessible  = true

  skip_final_snapshot = true


  depends_on = [aws_db_instance.RDS , aws_db_subnet_group.secondary_group]
}
