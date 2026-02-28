# --- RDS (Single-AZ, cost-optimized) ---

variable "db_name" {
  type    = string
  default = "accounts"
}

variable "db_username" {
  type    = string
  default = "admin"
}

# Prefer setting via TF_VAR_db_password/terraform.tfvars; if omitted, a deterministic fallback is generated.
variable "db_password" {
  type      = string
  sensitive = true
  default   = null
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = { Name = "${local.name}-db-subnet-group" }
}

resource "aws_db_instance" "mysql" {
  identifier = "${local.name}-mysql"

  engine         = "mysql"
  engine_version = "8.0" # ổn định, phổ biến; có thể đổi nếu bạn cần đúng version
  instance_class = var.db_instance_class

  db_name  = var.db_name
  username = var.db_username
  password = local.effective_db_password

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"

  multi_az               = false
  publicly_accessible    = false
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.this.name

  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true

  tags = { Name = "${local.name}-mysql" }
}

output "rds_endpoint" {
  value = aws_db_instance.mysql.address
}

output "rds_port" {
  value = aws_db_instance.mysql.port
}
