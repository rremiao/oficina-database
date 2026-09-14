# oficina-database

Infraestrutura como código (Terraform) do banco de dados gerenciado da oficina — Terceiro Tech
Challenge da Pós-Tech em Arquitetura de Software (FIAP).

## Propósito

Provisionar e versionar, de forma independente dos demais componentes, o banco de dados relacional
usado pela [API principal (`oficina`)](https://github.com/rremiao/oficina) e consultado diretamente
pela [function serverless de autenticação (`oficina-lambda`)](https://github.com/rremiao/oficina-lambda).
Este repositório é dono apenas da infraestrutura do banco — o schema (tabelas, migrations, índices)
continua versionado no repositório `oficina`, que é quem efetivamente acessa os dados via Flyway e
Spring Data JPA.

## Tecnologias

- Terraform (~> 1.5)
- AWS Provider (~> 5.0)
- Amazon RDS para PostgreSQL 15+
- GitHub Actions (validação da infraestrutura)

## Pré-requisitos

- Terraform >= 1.5.0
- Credenciais AWS configuradas (`aws configure` ou variáveis `AWS_ACCESS_KEY_ID` /
  `AWS_SECRET_ACCESS_KEY` / `AWS_SESSION_TOKEN`, no caso do AWS Academy/Learner Lab)
- Acesso à VPC default da conta (cenário padrão no Learner Lab)

## Estrutura

```text
.
|-- infra/
|   |-- main.tf                     # security group, subnet group e instância RDS
|   |-- variables.tf
|   |-- outputs.tf
|   |-- providers.tf
|   |-- versions.tf
|   `-- terraform.tfvars.example
|-- docs/
|   |-- der.md                      # diagrama entidade-relacionamento do schema
|   |-- rfc/0001-escolha-do-banco-de-dados.md
|   `-- adr/0001-segregacao-do-state-de-banco.md
`-- .github/workflows/infra-database.yml
```

## Arquitetura

```mermaid
flowchart LR
    subgraph VPC["VPC default (AWS Academy)"]
        SG["Security Group\n(porta 5432, origem: CIDR da VPC)"]
        RDS[("RDS PostgreSQL\noficina-db")]
        SG --- RDS
    end

    EKS["Pods da API\n(cluster oficina-kubernetes)"] -->|"JDBC :5432"| SG
    LAMBDA["Lambda auth-token\n(oficina-lambda)"] -->|"SELECT cliente\n(fora da VPC via ENI)"| SG
```

O RDS não é publicamente acessível (`publicly_accessible = false`); só recebe conexões de dentro da
VPC. A API (rodando no EKS) e a Lambda (configurada com ENI na mesma VPC) alcançam o banco pela porta
5432, liberada no security group para o CIDR da VPC inteira — suficiente no cenário de uma única VPC
por sandbox do Learner Lab.

## Execução e deploy

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
# edite terraform.tfvars com a senha do banco e demais parâmetros

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Após o `apply`, os outputs relevantes para os outros repositórios são:

- `rds_endpoint` / `rds_port` / `jdbc_url` — usados no `ConfigMap` da aplicação
  (`oficina-kubernetes`/`oficina`).
- `rds_security_group_id` — caso outro componente precise ser liberado explicitamente no security
  group do banco.

```bash
terraform output
```

Para destruir o ambiente ao final do Lab:

```bash
terraform destroy
```

Esse é o **último** repositório a derrubar (a Lambda e a app do `oficina-kubernetes` dependem deste
RDS). Ordem completa entre os 4 repositórios, com o porquê de cada passo, no
[runbook do ambiente completo](https://github.com/rremiao/oficina-kubernetes/blob/main/docs/runbook-ambiente-completo.md)
(repositório `oficina-kubernetes`).

## Pipeline (CI/CD)

O workflow [`infra-database.yml`](.github/workflows/infra-database.yml) roda em push/PR para `main`
e valida o Terraform (`fmt -check`, `init -backend=false`, `validate`). O `apply`/`destroy` **não**
são executados pela pipeline — o Learner Lab não garante credenciais persistentes entre execuções do
GitHub Actions, então o provisionamento é manual, a partir da máquina de quem está com a sessão AWS
Academy ativa.

## Modelo de dados

O diagrama entidade-relacionamento completo, com as observações sobre o schema atual, está em
[`docs/der.md`](docs/der.md). A justificativa da escolha do PostgreSQL como banco gerenciado está em
[`docs/rfc/0001-escolha-do-banco-de-dados.md`](docs/rfc/0001-escolha-do-banco-de-dados.md).

## Decisões arquiteturais

- [ADR-0001 — Segregação do state de banco em repositório próprio](docs/adr/0001-segregacao-do-state-de-banco.md)

## Swagger / Postman

Não aplicável — este repositório não expõe API própria. A documentação OpenAPI da aplicação que
consome este banco está no repositório [`oficina`](https://github.com/rremiao/oficina).
