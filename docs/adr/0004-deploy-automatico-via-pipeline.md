# ADR-0004 — Deploy automático via pipeline, com state remoto

## Status

Aceito

## Contexto

O enunciado do Tech Challenge exige que as pipelines dos repositórios de infraestrutura "validem e
apliquem" o Terraform, não só validem. Até este ADR, `infra-database.yml` só validava
(`fmt -check`, `init -backend=false`, `validate`) — o `apply` era sempre manual, e o Terraform usava
**state local**, nunca commitado.

Isso criava dois problemas pra automatizar o `apply` de verdade:

1. **State local não sobrevive entre execuções da pipeline** — cada run do GitHub Actions começa
   numa máquina limpa. Sem state remoto, um `apply` automático não saberia que o RDS já existe e
   tentaria recriá-lo (ou falharia por conflito de nome de recurso já existente na AWS).
2. **Credenciais do AWS Academy são de sessão** — expiram em poucas horas e mudam a cada reinício do
   Lab. Isso não impede um `apply` automático pontual, mas impede que a pipeline funcione sozinha
   indefinidamente sem intervenção humana.

## Decisão

1. Adotar **backend S3 parcial** (`backend "s3" {}` em `versions.tf`), com o bucket configurado via
   `-backend-config` — mesmo padrão já usado no `oficina-lambda`. Bucket criado manualmente uma vez
   (bootstrap, documentado no README), não pelo próprio Terraform (problema de ovo-e-galinha).
2. Adicionar um job `deploy` na pipeline, que roda `terraform apply -auto-approve` em push na `main`
   (ou disparo manual), usando os 3 secrets de credenciais AWS + `DB_PASSWORD` como GitHub Secrets, e
   o nome do bucket como GitHub Variable (`TF_STATE_BUCKET`).
3. **Não** tentar contornar a limitação de credenciais de sessão — o job falha com uma mensagem clara
   se as credenciais estiverem inválidas/expiradas, em vez de tentar qualquer mecanismo de refresh
   automático (não existe um viável dentro do Academy).

## Justificativa

- Resolve o "deploy automático" exigido pelo enunciado dentro do que é honestamente possível no AWS
  Academy: automático **enquanto a sessão do Lab está ativa e os secrets foram atualizados**, não
  "roda sozinho pra sempre" — o que nenhum dos 4 repositórios deste projeto consegue prometer, dado o
  provedor de nuvem escolhido.
- Mantém paridade com o que já existia no `oficina` e no `oficina-lambda`, que já dependiam do mesmo
  padrão de secrets atualizados manualmente. Antes deste ADR, `oficina-database` e
  `oficina-kubernetes` eram os únicos dois repositórios com um padrão diferente (só validação) sem
  justificativa técnica que os distinguisse dos outros dois — era inconsistência, não uma limitação
  real exclusiva desses dois repositórios.

## Consequências

- **Positivas**: pipeline agora atende literalmente ao texto do enunciado ("validar e aplicar os
  códigos Terraform" nos repositórios de infraestrutura).
- **Negativas / trade-offs**:
  - Precisa lembrar de atualizar os 3 secrets de AWS antes de cada push que deva disparar um deploy
    real — não é diferente do que já era necessário pro `oficina-lambda`, mas é uma etapa manual a
    mais toda vez que a sessão do Lab é reiniciada.
  - Introduz um bucket S3 adicional (`oficina-database-tfstate-<account-id>`) pra manter — mais um
    recurso pra lembrar que existe fora do ciclo de vida normal do `terraform destroy` deste
    repositório (o bucket de state nunca é destruído pelo `destroy`, de propósito).
