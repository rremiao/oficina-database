# Infraestrutura do banco de dados gerenciado (RDS PostgreSQL) da oficina.
#
# Extraído do repositório `oficina` (infra/aws/main.tf), que hoje concentra tanto o banco quanto o
# cluster EKS num único state. Este repositório passa a ser dono apenas do RDS, conforme a
# segregação de repositórios exigida pelo Tech Challenge Fase 3.

data "aws_caller_identity" "current" {}

data "aws_vpc" "selected" {
  id      = var.vpc_id != "" ? var.vpc_id : null
  default = var.vpc_id == "" ? true : null
}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

locals {
  common_tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
    Lab       = "aws-academy"
    Repo      = "oficina-database"
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Permite acesso PostgreSQL dentro da VPC"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "PostgreSQL dentro da VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    description = "Saida liberada"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-rds-sg"
  })
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = data.aws_subnets.selected.ids

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-db-subnet-group"
  })
}

resource "aws_db_instance" "postgres" {
  identifier             = var.db_identifier
  engine                 = "postgres"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 0
  apply_immediately       = true

  tags = merge(local.common_tags, {
    Name = var.db_identifier
  })
}
