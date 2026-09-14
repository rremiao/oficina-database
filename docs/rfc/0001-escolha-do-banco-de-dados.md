# RFC-0001 — Escolha do banco de dados gerenciado

## Status

Proposto

## Contexto

O Tech Challenge Fase 3 exige um banco de dados gerenciado na nuvem, com liberdade de escolha entre
PostgreSQL, MySQL, SQL Server ou outra tecnologia, desde que a decisão seja formalmente justificada.
A aplicação principal (`oficina`) já roda com PostgreSQL desde as fases anteriores do curso, usando
Flyway para versionamento de schema e Spring Data JPA para acesso a dados.

## Alternativas consideradas

| Opção | Prós | Contras |
|---|---|---|
| **PostgreSQL (RDS)** | Já é o banco usado pela aplicação desde a Fase 1; suporte nativo a índices funcionais e expressões (usados no índice de CPF normalizado); tipos ricos (`JSONB`, `NUMERIC` de precisão arbitrária); free tier / instância `db.t3.micro` suficiente no AWS Academy | Nenhum bloqueio identificado no escopo deste projeto |
| MySQL (RDS) | Também suportado nativamente pelo RDS; ecossistema amplo | Migração do schema e das migrations Flyway já existentes; menos expressivo em índices funcionais/parciais, usados na consulta por CPF |
| SQL Server (RDS) | Ferramental corporativo maduro | Licenciamento mais caro mesmo em modo *License Included*; sem ganho técnico relevante para o domínio da oficina; reescrita do schema |

## Decisão

Manter **PostgreSQL**, provisionado como **Amazon RDS** neste repositório (`oficina-database`).

## Justificativa

1. **Continuidade**: o schema, as migrations Flyway e o código de acesso a dados da aplicação já
   existem e são testados em cima de PostgreSQL desde fases anteriores do curso. Trocar de banco
   agora não traria benefício técnico proporcional ao custo de migração.
2. **Índices funcionais**: a autenticação por CPF (function serverless do `oficina-lambda`) depende
   de um índice sobre uma expressão (`regexp_replace(cpf_cnpj, '\D', '', 'g')`) para evitar *seq
   scan* na tabela `cliente` a cada login — recurso de primeira classe no PostgreSQL, com suporte
   mais limitado em MySQL e mais burocrático em SQL Server.
3. **Custo no Learner Lab**: `db.t3.micro` com RDS PostgreSQL é suportado pelo ambiente acadêmico
   (AWS Academy) sem exigir licenciamento adicional, ao contrário do SQL Server.
4. **Gerenciado**: usar RDS (em vez de um PostgreSQL auto-hospedado no EKS) atende diretamente ao
   requisito de "banco de dados gerenciado" do desafio, com backup, patching e monitoramento básico
   (CloudWatch) oferecidos pela AWS.

## Consequências

- A infraestrutura do RDS PostgreSQL passa a ser provisionada e versionada exclusivamente neste
  repositório (`oficina-database/infra`), separada do cluster Kubernetes (`oficina-kubernetes`) e da
  aplicação (`oficina`).
- O schema relacional (tabelas, migrations, índices) continua sendo responsabilidade do repositório
  `oficina`, que é quem efetivamente lê/escreve nesse banco via Flyway. Este repositório documenta o
  modelo (ver [`der.md`](../der.md)) mas não o versiona — evita duas fontes de verdade divergentes
  para o mesmo schema.
