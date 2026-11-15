# ADR-0005 — Bancos dos microsserviços no mesmo RDS

## Status

Aceito

## Contexto

Na Fase 4 o monólito virou três microsserviços, cada um com o próprio banco:

| Serviço | Banco |
|---|---|
| OS Service | PostgreSQL `os_service` (Flyway) |
| Billing Service | PostgreSQL `billing` (Flyway) |
| Execution Service | MongoDB próprio, dentro do cluster (fora deste repositório) |

O Terraform deste repositório cria uma instância RDS com um único banco (`db_name`, padrão
`oficina`). Se OS e Billing apontassem para ele, as duas migrações Flyway disputariam a mesma tabela
`flyway_schema_history` e as tabelas de um serviço ficariam visíveis para o outro.

Uma segunda instância RDS dobraria o custo no Learner Lab. E o banco não pode ser criado pelo próprio
Terraform (provider `postgresql`), porque o RDS não é público e o runner do GitHub está fora da VPC.

## Decisão

Uma instância RDS, com um banco por serviço: `os_service` e `billing`. O pipeline cria os dois logo
depois do `terraform apply`, com o script
[`scripts/criar-bancos-microsservicos.sh`](../../scripts/criar-bancos-microsservicos.sh): um pod
descartável com `psql` no cluster EKS (mesma VPC) roda `CREATE DATABASE` só para o banco que ainda
não existe. Rodar de novo não muda nada.

## Consequências

- Isolamento lógico entre os serviços (cada um só recebe a URL do próprio banco), sem custo extra.
- Os serviços continuam dividindo CPU, memória e conexões da mesma instância `db.t3.micro`.
- O passo depende do cluster: se o RDS subir antes do EKS, o pipeline só avisa, e é preciso rodar o
  workflow de novo (Run workflow) depois que o cluster estiver no ar.
- A senha é a do usuário master. Usuário próprio por serviço fica como melhoria futura.
