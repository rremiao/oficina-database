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
