-- scripts/lab5/01-perfil-tiendasur.sql
-- Lab 5 - Perfil del banco de pruebas TiendaSur

WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 180 PAGESIZE 100
SET FEEDBACK ON VERIFY OFF
ALTER SESSION SET CONTAINER = FREEPDB1;

PROMPT
PROMPT ===== 1. TABLAS: FILAS, BLOQUES, BYTES POR FILA Y BFR =====

COLUMN table_name FORMAT A12
COLUMN r FORMAT 999999999
COLUMN b FORMAT 999999
COLUMN r_bytes FORMAT 999999
COLUMN bfr FORMAT 999999
COLUMN mb FORMAT 999999.9

SELECT t.table_name,
       t.num_rows AS r,
       t.blocks AS b,
       t.avg_row_len AS r_bytes,
       ROUND(t.num_rows / NULLIF(t.blocks, 0)) AS bfr,
       ROUND(s.bytes / 1048576, 1) AS mb,
       TO_CHAR(t.last_analyzed, 'YYYY-MM-DD HH24:MI') AS last_analyzed
FROM dba_tables t
JOIN dba_segments s
  ON s.owner = t.owner
 AND s.segment_name = t.table_name
WHERE t.owner = 'TIENDASUR'
ORDER BY t.table_name;

PROMPT
PROMPT ===== 2. SESGOS DE CLIENTES =====

SELECT 'cliente pais = ES' AS dato,
       ROUND(100 * SUM(CASE WHEN pais = 'ES' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct
FROM tiendasur.cliente
UNION ALL
SELECT 'cliente ciudad = Lorca',
       ROUND(100 * SUM(CASE WHEN ciudad = 'Lorca' THEN 1 ELSE 0 END) / COUNT(*), 1)
FROM tiendasur.cliente
UNION ALL
SELECT 'cliente apellidos LIKE Gonz%',
       ROUND(100 * SUM(CASE WHEN apellidos LIKE 'Gonz%' THEN 1 ELSE 0 END) / COUNT(*), 1)
FROM tiendasur.cliente;

PROMPT
PROMPT ===== 3. DISTRIBUCION DE ESTADOS DE PEDIDOS =====

SELECT estado,
       COUNT(*) AS filas,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS porcentaje
FROM tiendasur.pedido
GROUP BY estado
ORDER BY estado;

PROMPT
PROMPT ===== 4. INDICES DEL BANCO =====

SELECT index_name, uniqueness, index_type
FROM dba_indexes
WHERE owner = 'TIENDASUR'
ORDER BY index_name;

PROMPT
PROMPT ===== PERFIL TIENDASUR FINALIZADO =====
EXIT
