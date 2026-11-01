#!/usr/bin/env bash
# scripts/ops/sysdba.sh — ejecuta un archivo SQL como SYSDBA
set -euo pipefail
source scripts/deployment/env/00-config.sh

SQL_FILE="${1:?Uso: bash scripts/ops/sysdba.sh archivo.sql [evidencia.log]}"
LOG="${2:-}"

if [ ! -f "$SQL_FILE" ]; then
    echo "ERROR: no existe $SQL_FILE" >&2
    exit 2
fi

if [ -n "$LOG" ]; then
    mkdir -p "$(dirname "$LOG")"
    docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba < "$SQL_FILE" | tee "$LOG"
else
    docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba < "$SQL_FILE"
fi
