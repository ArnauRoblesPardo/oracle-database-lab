WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 160 PAGESIZE 100 FEEDBACK OFF
COLUMN name FORMAT A48
COLUMN type FORMAT A28
COLUMN value FORMAT A60

PROMPT ===== 1. Copias del control file (multiplexacion) =====
SELECT name, status, block_size, file_size_blks
FROM v$controlfile;

PROMPT ===== 2. Secciones del control file =====
SELECT type, records_total, records_used
FROM v$controlfile_record_section
WHERE records_used > 0
ORDER BY records_used DESC
FETCH FIRST 10 ROWS ONLY;

PROMPT ===== 3. Dias de conservacion de registros =====
SELECT name, value
FROM v$parameter
WHERE name = 'control_file_record_keep_time';

PROMPT ===== 4. Copia logica de seguridad del control file =====
ALTER DATABASE BACKUP CONTROLFILE TO TRACE
AS '/opt/oracle/oradata/FREE/controlfile_lab5.trc' REUSE;

PROMPT Creado controlfile_lab5.trc dentro del volumen
EXIT
