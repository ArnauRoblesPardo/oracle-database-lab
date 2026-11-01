-- scripts/lab4/06-arranque-por-etapas.sql
-- Parada y arranque etapa a etapa: SHUTDOWN -> NOMOUNT -> MOUNT -> OPEN
-- Ejecutar como SYSDBA mediante scripts/ops/sysdba.sh

WHENEVER SQLERROR CONTINUE
SET LINESIZE 160 PAGESIZE 100 FEEDBACK OFF ECHO OFF
COLUMN instance_name FORMAT A10
COLUMN name FORMAT A40
COLUMN value FORMAT A70

PROMPT
PROMPT ===== 0. Punto de partida =====
SELECT instance_name, status, database_status FROM v$instance;

PROMPT
PROMPT ===== 1. SHUTDOWN IMMEDIATE =====
SHUTDOWN IMMEDIATE

PROMPT
PROMPT ===== 2. STARTUP NOMOUNT =====
STARTUP NOMOUNT
SELECT instance_name, status FROM v$instance;

PROMPT -- v$parameter ya responde:
SELECT name, value FROM v$parameter
WHERE name IN ('control_files', 'db_name', 'spfile');

PROMPT -- ORA-01507 es esperado: la base aun no esta montada
SELECT name, open_mode FROM v$database;

PROMPT
PROMPT ===== 3. ALTER DATABASE MOUNT =====
ALTER DATABASE MOUNT;
SELECT instance_name, status FROM v$instance;
SELECT name, open_mode, log_mode FROM v$database;
SELECT name FROM v$controlfile;
SELECT COUNT(*) AS datafiles_conocidos FROM v$datafile;

PROMPT -- ORA-01219 es esperado: el diccionario aun no esta accesible
SELECT COUNT(*) FROM dba_tables;

PROMPT
PROMPT ===== 4. ALTER DATABASE OPEN =====
ALTER DATABASE OPEN;
SELECT instance_name, status, database_status FROM v$instance;
SELECT name, open_mode FROM v$database;
SELECT con_id, name, open_mode, restricted FROM v$pdbs ORDER BY con_id;

COLUMN con_name FORMAT A12
COLUMN instance_name FORMAT A12
COLUMN state FORMAT A8

SELECT con_name, instance_name, state FROM dba_pdb_saved_states;

PROMPT
PROMPT ===== 5. ADR y alert log =====
SELECT name, value FROM v$diag_info
WHERE name IN ('ADR Home', 'Diag Trace', 'Default Trace File');

EXIT
