#!/usr/bin/env bash
# Simulacro A: caída brusca de la instancia
set -euo pipefail
source scripts/deployment/env/00-config.sh

sql() {
  docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba
}

echo "== 1. Transacción confirmada y otra sin confirmar =="
sql <<'SQL'
SET FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
UPDATE admin_academia.aca_estudiantes
SET estado = 'EGRESADO'
WHERE estudiante_id = 102;
COMMIT;

UPDATE admin_academia.aca_estudiantes
SET estado = 'INACTIVO'
WHERE estudiante_id = 103;

PROMPT 102 -> EGRESADO (confirmado); 103 -> INACTIVO (sin confirmar)
ALTER SESSION SET CONTAINER = CDB$ROOT;
SHUTDOWN ABORT
SQL

echo "== 2. Arranque normal: recuperación automática =="
printf "STARTUP\nEXIT\n" | sql
bash scripts/ops/esperar-healthy.sh

echo "== 3. Comprobar qué cambios sobrevivieron =="
sql <<'SQL'
SET FEEDBACK ON
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT estudiante_id, estado
FROM admin_academia.aca_estudiantes
WHERE estudiante_id IN (102, 103)
ORDER BY 1;

PROMPT Devolvemos la fila 102 a ACTIVO
UPDATE admin_academia.aca_estudiantes
SET estado = 'ACTIVO'
WHERE estudiante_id = 102;
COMMIT;
SQL

echo "== 4. Recuperación registrada en el alert log =="
docker exec "$CONT_NAME" bash -c \
  'tail -n 400 /opt/oracle/diag/rdbms/*/*/trace/alert_*.log' |
  grep -E 'Shutting down .*\(abort\)|shutdown \(abort\)|Beginning crash recovery|Recovery starting at|redo scan|need recovery|redo application|Completed crash recovery|opened at log sequence' |
  tail -12
