variable "aws_region" {
  description = "Região AWS usada no Learner Lab."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome base dos recursos."
  type        = string
  default     = "oficina"
}

variable "db_identifier" {
  description = "Identificador da instância RDS."
  type        = string
  default     = "oficina-db"
}

variable "db_name" {
  description = "Nome do banco PostgreSQL."
  type        = string
  default     = "oficina"
}

variable "db_username" {
  description = "Usuário master do PostgreSQL no RDS."
  type        = string
  default     = "oficina_user"
}

variable "db_password" {
  description = "Senha master do PostgreSQL no RDS."
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Classe da instância RDS."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Armazenamento alocado para o RDS, em GB."
  type        = number
  default     = 20
}

variable "vpc_id" {
  description = <<EOT
ID da VPC onde o RDS deve ser provisionado. Deixe em branco para usar a VPC default da conta
(cenário do AWS Academy/Learner Lab, que provisiona uma única VPC default por sandbox).
EOT
  type        = string
  default     = ""
}
