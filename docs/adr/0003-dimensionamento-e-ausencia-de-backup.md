# ADR-0003 — Dimensionamento `db.t3.micro` e ausência deliberada de backup

## Status

Aceito — **válido apenas para o ambiente acadêmico**

## Contexto

O RDS deste projeto roda no AWS Academy Learner Lab: crédito limitado, sessões de 4 horas e o
ambiente inteiro destruído ao fim de cada sessão de testes. O banco é recriado do zero a cada
subida, e o schema é reconstruído pelo Flyway no boot da aplicação.

Nesse cenário, as escolhas de dimensionamento e resiliência que fariam sentido em produção custam
dinheiro e tempo de provisionamento sem entregar valor nenhum.

## Alternativas consideradas

| Opção | Prós | Contras |
|---|---|---|
| **`db.t3.micro`, 20 GB, sem backup, sem Multi-AZ** | Provisiona em poucos minutos; consumo mínimo do crédito do Lab | Poucas conexões simultâneas; nenhuma resiliência |
| `db.t3.small` ou maior | Mais conexões e memória | Consome crédito mais rápido, sem necessidade real no volume de demonstração |
| `backup_retention_period > 0` | Permite restaurar | O banco é descartável e recriado pelo Flyway; snapshots ocupariam armazenamento e atrasariam o `destroy` |
| Multi-AZ | Alta disponibilidade | Dobra o custo para um ambiente que vive 4 horas |

## Decisão

- `db_instance_class = "db.t3.micro"`, `db_allocated_storage = 20`
- `backup_retention_period = 0`
- `skip_final_snapshot = true`
- `deletion_protection = false`
- `apply_immediately = true`
- Sem Multi-AZ

## Justificativa

1. **O banco é descartável por construção.** Cada subida recria a instância e o Flyway reconstrói o
   schema da `V1` à `V10`. Não há dado de produção a proteger.
2. **`skip_final_snapshot` e `deletion_protection = false` existem para o `destroy` funcionar.** Com
   proteção ligada, o `terraform destroy` falha e o recurso fica ligado consumindo crédito — o
   oposto do que se quer no fim de uma sessão do Lab.
3. **`apply_immediately = true`** evita esperar a janela de manutenção para uma mudança entrar, o
   que numa sessão de 4 horas seria inviável.

## Consequências

- **Positivas**: subida e destruição rápidas, consumo mínimo de crédito, ciclo de teste curto.
- **Negativas / trade-offs**:
  - **Nenhuma destas escolhas é aceitável em produção.** Um ambiente real precisaria de retenção de
    backup, `deletion_protection = true`, snapshot final e provavelmente Multi-AZ. Este ADR existe
    para deixar registrado que a configuração atual é consciente e limitada ao contexto acadêmico.
  - O `db.t3.micro` tem poucas conexões simultâneas, e elas são disputadas pelo pool da aplicação
    (`SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE: "2"`) e pela function `auth-token`. É exatamente
    por isso que a function limita a concorrência a 5 (ADR-0004 do `oficina-lambda`) — as duas
    decisões estão acopladas: mexer em uma exige revisar a outra.
  - Sem backup, um `destroy` acidental no meio de uma demonstração significa recriar e semear os
    dados de teste de novo.
