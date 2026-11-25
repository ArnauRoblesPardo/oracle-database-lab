WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 160 PAGESIZE 100 FEEDBACK OFF
COLUMN name FORMAT A48
COLUMN hora_del_scn FORMAT A20
COLUMN archivo FORMAT A16
COLUMN value FORMAT A12

PROMPT ===== 1. El SCN avanza aunque nadie haga nada =====
SELECT current_scn,
       TO_CHAR(SCN_TO_TIMESTAMP(current_scn), 'YYYY-MM-DD HH24:MI:SS') AS hora_del_scn
FROM v$database;

EXEC DBMS_SESSION.SLEEP(3)

SELECT current_scn FROM v$database;

PROMPT ===== 2. Ultimo checkpoint: control file frente a cabeceras =====
SELECT checkpoint_change# AS ckpt_en_control_file
FROM v$database;

SELECT d.file#, d.con_id,
       REGEXP_SUBSTR(d.name, '[^/]+$') AS archivo,
       d.checkpoint_change# AS ckpt_control_file,
       h.checkpoint_change# AS ckpt_cabecera,
       CASE
         WHEN d.checkpoint_change# = h.checkpoint_change# THEN 'sincronizado'
         ELSE 'DISTINTO'
       END AS estado
FROM v$datafile d
JOIN v$datafile_header h ON h.file# = d.file#
WHERE d.file# <= 4 OR d.name LIKE '%academia%'
ORDER BY d.file#;

PROMPT ===== 3. Cambiamos datos y forzamos un CHECKPOINT completo =====
ALTER SESSION SET CONTAINER = FREEPDB1;

UPDATE admin_academia.aca_estudiantes
SET estado = estado
WHERE estudiante_id <= 1000;

COMMIT;

ALTER SESSION SET CONTAINER = CDB$ROOT;
ALTER SYSTEM CHECKPOINT;

SELECT checkpoint_change# AS ckpt_en_control_file, current_scn
FROM v$database;

SELECT d.file#, d.con_id,
       REGEXP_SUBSTR(d.name, '[^/]+$') AS archivo,
       d.checkpoint_change# AS ckpt_control_file,
       h.checkpoint_change# AS ckpt_cabecera
FROM v$datafile d
JOIN v$datafile_header h ON h.file# = d.file#
WHERE d.file# <= 4 OR d.name LIKE '%academia%'
ORDER BY d.file#;

PROMPT ===== 4. Estimacion de recuperacion de instancia (MTTR) =====
SELECT target_mttr, estimated_mttr, recovery_estimated_ios, actual_redo_blks
FROM v$instance_recovery;

SELECT name, value
FROM v$parameter
WHERE name IN ('fast_start_mttr_target', 'log_checkpoint_interval', 'log_checkpoint_timeout');

EXIT
