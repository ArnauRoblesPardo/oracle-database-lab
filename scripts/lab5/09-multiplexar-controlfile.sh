#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh

NUEVA="/opt/oracle/oradata/FREE/control03.ctl"

sql() {
  docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba
}

ACTUAL=$(sql <<'SQL'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 LINESIZE 400
SELECT value FROM v$parameter WHERE name = 'control_files';
EXIT
SQL
)
ACTUAL=$(echo "$ACTUAL" | xargs)

echo "Control files actuales: $ACTUAL"

if [[ "$ACTUAL" == *control03.ctl* ]]; then
  echo "La tercera copia ya existe. No hay nada que hacer."
  exit 0
fi

LISTA="'$(echo "$ACTUAL" | sed "s/, */','/g")','$NUEVA'"

echo "== 1. Configurar las tres copias en el SPFILE =="
printf "ALTER SYSTEM SET control_files = %s SCOPE = SPFILE;\nEXIT\n" "$LISTA" | sql

echo "== 2. Apagar Oracle limpiamente =="
printf "SHUTDOWN IMMEDIATE\nEXIT\n" | sql

echo "== 3. Copiar un control file sano =="
PRIMERA=$(echo "$ACTUAL" | cut -d, -f1 | xargs)
docker exec "$CONT_NAME" cp -p "$PRIMERA" "$NUEVA"
docker exec "$CONT_NAME" ls -l /opt/oracle/oradata/FREE/control*.ctl

echo "== 4. Arrancar Oracle y comprobar las tres copias =="
sql <<'SQL'
STARTUP
SET LINESIZE 120
COLUMN name FORMAT A48
SELECT name, status FROM v$controlfile;
EXIT
SQL

bash scripts/ops/esperar-healthy.sh
