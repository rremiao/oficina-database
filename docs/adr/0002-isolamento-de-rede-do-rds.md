# ADR-0002 — Isolamento de rede do RDS: instância privada, acesso só de dentro da VPC

## Status

Aceito

## Contexto

O banco precisa ser alcançado por dois consumidores que vivem em lugares diferentes: os Pods da
aplicação no cluster EKS (`oficina-kubernetes`) e a function `auth-token` (`oficina-lambda`), que
consulta o cliente por CPF no momento do login.

Havia ainda um terceiro tipo de acesso a considerar: o operacional — semear dados de teste, conferir
se o Flyway rodou, investigar um problema.

## Alternativas consideradas

| Opção | Prós | Contras |
|---|---|---|
| **`publicly_accessible = false`, ingress 5432 só do CIDR da VPC** | O banco não é alcançável da internet; um vazamento de senha não basta para acessar | Acesso operacional exige estar dentro da VPC (pod efêmero ou bastion) |
| `publicly_accessible = true` com security group restrito por IP | Acesso direto do laptop, sem pod intermediário | O IP do Learner Lab muda a cada sessão; manter a regra viraria trabalho manual constante, e uma regra frouxa expõe o banco |
| Instância privada + bastion EC2 | Acesso operacional confortável e auditável | Mais uma instância para subir, pagar e derrubar a cada sessão do Lab |

## Decisão

A instância é **privada** (`publicly_accessible = false`) e o security group libera a porta 5432
apenas para o **CIDR da própria VPC**, não para `0.0.0.0/0` nem por IP de origem.

O acesso operacional é feito por um **pod efêmero dentro do cluster**, sem bastion:

```bash
kubectl run psql-seed -n oficina --rm -i --restart=Never --image=postgres:16 \
  --env=PGPASSWORD="$DB_PASS" --command -- \
  psql -h "$RDS_ENDPOINT" -U "$DB_USER" -d oficina -c "..."
```

## Justificativa

1. **Liberar por CIDR da VPC atende aos dois consumidores de uma vez.** Os Pods do EKS e a Lambda
   `auth-token` (que roda dentro da VPC, ver ADR-0006 do `oficina-lambda`) ficam ambos cobertos sem
   regra específica por origem.
2. **O pod efêmero substitui o bastion sem custo.** Ele nasce, executa o comando e some com o
   `--rm`, sem deixar superfície de ataque permanente nem recurso para lembrar de destruir.
3. **A senha sozinha não dá acesso.** Como o endpoint não é roteável da internet, um vazamento da
   senha em log ou em state exige também acesso à rede para ser explorado.

## Consequências

- **Positivas**: a superfície de exposição do banco é a VPC, não a internet; nenhuma regra de
  security group precisa ser mantida à mão entre sessões do Lab.
- **Negativas / trade-offs**:
  - Nenhuma ferramenta gráfica (DBeaver, pgAdmin) conecta direto do laptop. Toda inspeção passa por
    `kubectl run`, o que é mais incômodo.
  - O ingress libera a VPC inteira, não apenas os security groups dos consumidores. Num ambiente
    real, o correto seria referenciar os security groups de origem (`source_security_group_id`); a
    simplificação foi aceita porque a VPC default do Lab é de uso exclusivo deste projeto.
  - Depende da VPC default da conta. Numa conta com múltiplas VPCs, `vpc_id` precisaria ser
    informado explicitamente — a variável existe justamente para isso.
