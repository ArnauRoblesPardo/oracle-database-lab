#!/usr/bin/env bash
# La misma instancia vista desde Linux
set -euo pipefail
source scripts/deployment/env/00-config.sh

echo "== 1. Procesos de la instancia FREE =="
docker top "$CONT_NAME" -eo pid,user,rss,args \
  | grep -E '(ora|db)_[a-z0-9]+_FREE' | head -15 || true

echo "== Total de procesos de background =="
docker top "$CONT_NAME" -eo pid,args \
  | grep -cE ' (ora|db)_[a-z0-9]+_FREE' || true

echo "== 2. Procesos servidor y listener =="
docker top "$CONT_NAME" -eo pid,user,args \
  | grep -E 'oracleFREE|tnslsnr' || true

echo "== 3. Memoria del contenedor =="
docker stats --no-stream \
  --format 'table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}' "$CONT_NAME"

echo "== 4. Archivos del CDB y de FREEPDB1 =="
docker exec "$CONT_NAME" bash -c \
  'ls -lh /opt/oracle/oradata/FREE | grep -v ^total; echo "-- FREEPDB1 --"; ls -lh /opt/oracle/oradata/FREE/FREEPDB1 | grep -v ^total'

echo "== 5. Listener y servicios registrados =="
docker exec "$CONT_NAME" lsnrctl status \
  | grep -E 'Service|Instance|Listening|Uptime' || true
