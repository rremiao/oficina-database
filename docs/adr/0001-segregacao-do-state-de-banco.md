# ADR-0001 — Segregação do state de banco em repositório próprio

## Status

Aceito

## Contexto

O Tech Challenge Fase 3 exige quatro repositórios segregados, um dos quais dedicado exclusivamente
à infraestrutura do banco de dados gerenciado, provisionada via Terraform. Até a criação deste
repositório, os recursos de RDS PostgreSQL viviam no mesmo Terraform state do cluster EKS, dentro do
repositório `oficina` (`infra/aws/main.tf`).

## Decisão

O RDS PostgreSQL, seu security group e seu subnet group passam a ser definidos e aplicados
exclusivamente a partir do Terraform deste repositório (`oficina-database/infra`), com state próprio,
independente do state usado para o cluster Kubernetes (`oficina-kubernetes`) e da aplicação
(`oficina`).

## Consequências

- **Positivas**: cada repositório pode ter sua própria pipeline de CI/CD, seu próprio ciclo de vida
  de deploy e seu próprio dono técnico, sem acoplar o *apply*/*destroy* do banco ao do cluster.
  Atende diretamente à exigência de segregação de repositórios do desafio.
- **Negativas / trade-offs**:
  - O endpoint do RDS (`rds_endpoint`, exposto como output deste módulo) precisa ser propagado
    manualmente (ou via pipeline) para o `ConfigMap` consumido pela aplicação no
    `oficina-kubernetes`/`oficina`, já que não há mais um único `apply` que resolva as duas coisas
    juntas.
  - Sem *remote state* compartilhado (ex.: backend S3 + DynamoDB lock) configurado neste momento —
    o Learner Lab não garante credenciais persistentes entre execuções da pipeline — o repasse desse
    endpoint entre repositórios é feito manualmente, documentado no README deste repositório.
  - Ambos os módulos de infraestrutura (banco e Kubernetes) leem a VPC *default* da conta de forma
    independente. Isso é aceitável no cenário de sandbox do AWS Academy, onde há apenas uma VPC por
    conta, mas não seria a escolha correta num ambiente com múltiplas VPCs — nesse caso a VPC
    deveria ser um recurso compartilhado, referenciado por *data source* com um identificador fixo
    (ou por *remote state*) em vez de cada repositório assumir a VPC default.
