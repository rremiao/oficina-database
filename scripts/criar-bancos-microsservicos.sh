#!/usr/bin/env bash
# Cria no RDS os bancos dos microsservicos da Fase 4, se ainda nao existirem (ver ADR-0005).
#
# O RDS nao e publico, entao o psql roda num pod descartavel dentro do cluster EKS, que esta na mesma
# VPC. Precisa de kubectl apontando para o cluster (aws eks update-kubeconfig).
#
# Uso:
#   RDS_ENDPOINT=<endpoint> PGPASSWORD=<senha> ./scripts/criar-bancos-microsservicos.sh
#
# Opcionais: DB_USERNAME (oficina_user), DB_NAME (oficina, banco usado so para conectar),
# BANCOS ("os_service billing"), NAMESPACE (default).
set -euo pipefail

: "${RDS_ENDPOINT:?defina RDS_ENDPOINT (terraform output -raw rds_endpoint)}"
: "${PGPASSWORD:?defina PGPASSWORD com a senha do usuario master do RDS}"
DB_USERNAME="${DB_USERNAME:-oficina_user}"
DB_NAME="${DB_NAME:-oficina}"
BANCOS="${BANCOS:-os_service billing}"
NAMESPACE="${NAMESPACE:-default}"
POD="criar-bancos-$(date +%s)"

SQL=""
for banco in $BANCOS; do
	if ! [[ "$banco" =~ ^[a-z_][a-z0-9_]*$ ]]; then
		echo "nome de banco invalido: $banco" >&2
		exit 1
	fi
	# CREATE DATABASE nao aceita IF NOT EXISTS nem roda dentro de transacao: o \gexec so executa o
	# comando quando o SELECT devolve linha, ou seja, quando o banco ainda nao existe.
	SQL+="SELECT 'CREATE DATABASE ${banco}' WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = '${banco}')\\gexec
"
done
SQL+="SELECT datname AS bancos FROM pg_database WHERE NOT datistemplate ORDER BY 1;
"

echo "==> criando bancos ($BANCOS) em $RDS_ENDPOINT"
printf '%s' "$SQL" | kubectl run "$POD" --namespace "$NAMESPACE" \
	--image=postgres:16-alpine --restart=Never --rm -i --quiet \
	--pod-running-timeout=3m \
	--env="PGPASSWORD=$PGPASSWORD" \
	--command -- psql -h "$RDS_ENDPOINT" -U "$DB_USERNAME" -d "$DB_NAME" -v ON_ERROR_STOP=1
