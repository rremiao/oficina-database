output "account_id" {
  description = "Conta AWS atual."
  value       = data.aws_caller_identity.current.account_id
}

output "rds_endpoint" {
  description = "Endpoint do RDS PostgreSQL."
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "Porta do RDS."
  value       = aws_db_instance.postgres.port
}

output "rds_security_group_id" {
  description = "Security group do RDS, para liberar acesso a partir de outros componentes (ex.: EKS, Lambda)."
  value       = aws_security_group.rds.id
}

output "jdbc_url" {
  description = "URL JDBC para a aplicação."
  value       = "jdbc:postgresql://${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${var.db_name}"
}
