# oficina-database

Infraestrutura como código (Terraform) do **banco de dados gerenciado** (RDS PostgreSQL) usado pela API da oficina mecânica — Tech Challenge Fase 3 (POS Tech / SOAT).

Extraído do `infra/aws/` do repositório principal ([`oficina`](https://github.com/Franciscojr08/oficina)), mantendo somente a parte de banco. O cluster Kubernetes tem seu próprio repositório: [`oficina-kubernetes`](https://github.com/rremiao/oficina-kubernetes).

## O que este repositório provisiona

- Security Group liberando PostgreSQL (5432) só dentro da VPC default.
- DB Subnet Group.
- Instância **RDS PostgreSQL** (`oficina-db`, privada, sem acesso público), usando `db.t3.micro` por padrão.

Não provisiona: cluster Kubernetes (repo `oficina-kubernetes`), API Gateway/Lambda (repo `oficina-lambda`), nem a aplicação em si (repo `oficina`).

## Pré-requisitos

- Sessão ativa do **AWS Academy Learner Lab**, com credenciais temporárias exportadas (ou configuradas no profile `academy`).
- Terraform >= 1.5.0.

## Como rodar localmente

```bash
export TF_VAR_db_password='Oficina12345!'

terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Depois do `apply`, pegue o endpoint gerado (necessário para configurar a aplicação no repo `oficina`):

```bash
terraform output rds_endpoint
# ou, sem depender do state local:
aws rds describe-db-instances \
  --db-instance-identifier oficina-db \
  --region us-east-1 \
  --profile academy \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text
```

## Deploy pelo GitHub Actions

Workflow `.github/workflows/deploy.yml`, disparo manual (`workflow_dispatch`).

Secrets necessários no repositório:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN
AWS_REGION=us-east-1
DB_PASSWORD
```

Rode `deploy` para criar/atualizar o banco, `destroy` para removê-lo. O endpoint gerado aparece no log do job `deploy` (step "Terraform output").

## ⚠️ Orçamento do AWS Academy Lab

RDS cobra por hora mesmo parado (armazenamento + instância). Ao final de cada sessão de uso, rode `destroy` aqui e também no `oficina-kubernetes` — não deixe os dois provisionados de um dia para o outro sem necessidade.
