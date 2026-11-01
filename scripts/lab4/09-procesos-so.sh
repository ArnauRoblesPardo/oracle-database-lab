#!/usr/bin/env bash
# H.2: Los mismos procesos de Oracle vistos desde Linux.
# Lee /proc dentro del contenedor para comparar PID con SPID de Oracle.

set -euo pipefail

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

source scripts/deployment/env/00-config.sh

docker exec "$CONT_NAME" bash -c '
  printf "%-8s %-10s %s\n" PID RSS_MB PROCESO
  for d in /proc/[0-9]*; do
    pid=${d#/proc/}
    cmd=$(tr "\0" " " < "$d/cmdline" 2>/dev/null) || continue
    [ -n "$cmd" ] || continue
    rss=$(awk "/^VmRSS/ {printf \"%.0f\", \$2/1024}" "$d/status" 2>/dev/null)
    printf "%-8s %-10s %s\n" "$pid" "${rss:-0}" "$cmd"
  done
' > "$TMP"

echo "== 1. Procesos de background clave (compara PID con SPID de Oracle) =="
grep -E '_(pmon|lreg|smon|dbw0|lgwr|ckpt|mmon|mmnl|reco)_' "$TMP" || true

echo "== 2. Recuento por tipo =="
echo "    background (db_*_FREE / ora_*_FREE): $(grep -cE ' (db|ora)_[a-z0-9]+_FREE' "$TMP" || true)"
echo "    servidor dedicado (oracleFREE):       $(grep -c 'oracleFREE' "$TMP" || true)"
echo "    listener (tnslsnr):                   $(grep -c 'tnslsnr' "$TMP" || true)"

echo "== 3. Procesos servidor =="
grep 'oracleFREE' "$TMP" || echo "    (ninguno: puede que no haya una sesión dedicada visible)"

if [ -n "${1:-}" ]; then
  echo "== 4. El proceso con SPID $1 =="
  awk -v p="$1" '$1 == p' "$TMP"
fi
