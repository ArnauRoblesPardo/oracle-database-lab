#!/usr/bin/env bash
# Simulacro B: pérdida de una copia del control file
set -euo pipefail
source scripts/deployment/env/00-config.sh

sql() {
  docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba
}

CTL="$DATA_ROOT/FREE/control03.ctl"

docker exec "$CONT_NAME" test -f "$CTL" || {
  echo "No existe $CTL: ejecuta antes 09-multiplexar-controlfile.sh"
  exit 2
}

SANA=$(printf "SET HEADING OFF FEEDBACK OFF PAGESIZE 0\nSELECT name FROM v\$controlfile WHERE name <> '%s' AND ROWNUM = 1;\nEXIT\n" "$CTL" | sql | xargs)
[ -n "$SANA" ] || {
  echo "No encuentro otra copia del control file"
  exit 2
}

echo "Copia sana: $SANA"
echo "== 1. Parada limpia y borrado de control03.ctl =="
printf "SHUTDOWN IMMEDIATE\nEXIT\n" | sql
docker exec "$CONT_NAME" rm -f "$CTL"

echo "== 2. Arranque: ORA-00205 esperado =="
printf "STARTUP\nSELECT status FROM v\$instance;\nEXIT\n" | sql || true

echo "== 3. Diagnóstico en el alert log =="
docker exec "$CONT_NAME" bash -c \
  'tail -n 80 /opt/oracle/diag/rdbms/*/*/trace/alert_*.log' |
  grep -E 'ORA-00210|ORA-00202|ORA-27037|ORA-00205' |
  tail -4

echo "== 4. Reparación: copiar la copia sana =="
docker exec "$CONT_NAME" cp -p "$SANA" "$CTL"

sql <<'SQL'
ALTER DATABASE MOUNT;
ALTER DATABASE OPEN;
SET LINESIZE 120
COLUMN name FORMAT A48
SELECT name, status FROM v$controlfile;
EXIT
SQL

bash scripts/ops/esperar-healthy.sh
