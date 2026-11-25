-- scripts/lab5/13-lgwr-dbwn.sql
WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 160 PAGESIZE 100 FEEDBACK OFF VERIFY OFF

COLUMN paso FORMAT A34
COLUMN objd NEW_VALUE objd NOPRINT

ALTER SESSION SET CONTAINER = FREEPDB1;

SELECT data_object_id AS objd
FROM dba_objects
WHERE owner = 'ADMIN_ACADEMIA'
  AND object_name = 'ACA_ESTUDIANTES';

ALTER SESSION SET CONTAINER = CDB$ROOT;

PROMPT ===== Paso 0: checkpoint para partir de una cache sin bloques sucios =====
ALTER SYSTEM CHECKPOINT;

COLUMN redo0 NEW_VALUE redo0 NOPRINT
COLUMN lgwr0 NEW_VALUE lgwr0 NOPRINT
COLUMN commits0 NEW_VALUE commits0 NOPRINT
COLUMN dbwn0 NEW_VALUE dbwn0 NOPRINT
COLUMN sucios0 NEW_VALUE sucios0 NOPRINT

SELECT e.*,
       (SELECT COUNT(*) FROM v$bh WHERE objd = &objd AND dirty = 'Y') AS sucios0
FROM (
    SELECT MAX(DECODE(n.name, 'redo size', s.value)) AS redo0,
           MAX(DECODE(n.name, 'redo writes', s.value)) AS lgwr0,
           MAX(DECODE(n.name, 'user commits', s.value)) AS commits0,
           MAX(DECODE(n.name, 'physical writes from cache', s.value)) AS dbwn0
    FROM v$sysstat s
    JOIN v$statname n ON n.statistic# = s.statistic#
    WHERE n.name IN (
        'redo size',
        'redo writes',
        'user commits',
        'physical writes from cache'
    )
) e;

PROMPT ===== Paso 1: UPDATE de las 20 000 filas y COMMIT =====
ALTER SESSION SET CONTAINER = FREEPDB1;
UPDATE admin_academia.aca_estudiantes SET estado = estado;
COMMIT;
ALTER SESSION SET CONTAINER = CDB$ROOT;

COLUMN redo1 NEW_VALUE redo1 NOPRINT
COLUMN lgwr1 NEW_VALUE lgwr1 NOPRINT
COLUMN commits1 NEW_VALUE commits1 NOPRINT
COLUMN dbwn1 NEW_VALUE dbwn1 NOPRINT
COLUMN sucios1 NEW_VALUE sucios1 NOPRINT

SELECT e.*,
       (SELECT COUNT(*) FROM v$bh WHERE objd = &objd AND dirty = 'Y') AS sucios1
FROM (
    SELECT MAX(DECODE(n.name, 'redo size', s.value)) AS redo1,
           MAX(DECODE(n.name, 'redo writes', s.value)) AS lgwr1,
           MAX(DECODE(n.name, 'user commits', s.value)) AS commits1,
           MAX(DECODE(n.name, 'physical writes from cache', s.value)) AS dbwn1
    FROM v$sysstat s
    JOIN v$statname n ON n.statistic# = s.statistic#
    WHERE n.name IN (
        'redo size',
        'redo writes',
        'user commits',
        'physical writes from cache'
    )
) e;

PROMPT ===== Paso 2: CHECKPOINT: DBWn vuelca los bloques sucios =====
ALTER SYSTEM CHECKPOINT;

COLUMN redo2 NEW_VALUE redo2 NOPRINT
COLUMN lgwr2 NEW_VALUE lgwr2 NOPRINT
COLUMN commits2 NEW_VALUE commits2 NOPRINT
COLUMN dbwn2 NEW_VALUE dbwn2 NOPRINT
COLUMN sucios2 NEW_VALUE sucios2 NOPRINT

SELECT e.*,
       (SELECT COUNT(*) FROM v$bh WHERE objd = &objd AND dirty = 'Y') AS sucios2
FROM (
    SELECT MAX(DECODE(n.name, 'redo size', s.value)) AS redo2,
           MAX(DECODE(n.name, 'redo writes', s.value)) AS lgwr2,
           MAX(DECODE(n.name, 'user commits', s.value)) AS commits2,
           MAX(DECODE(n.name, 'physical writes from cache', s.value)) AS dbwn2
    FROM v$sysstat s
    JOIN v$statname n ON n.statistic# = s.statistic#
    WHERE n.name IN (
        'redo size',
        'redo writes',
        'user commits',
        'physical writes from cache'
    )
) e;

PROMPT
PROMPT ===== Resultado: lo que cambio en cada paso =====

SELECT '0. Punto de partida' AS paso,
       NULL AS redo_kb,
       NULL AS escrituras_lgwr,
       NULL AS commits_,
       NULL AS bloques_dbwn,
       &sucios0 AS bloques_sucios_tabla
FROM dual
UNION ALL
SELECT '1. UPDATE 20 000 filas + COMMIT',
       ROUND((&redo1 - &redo0) / 1024),
       &lgwr1 - &lgwr0,
       &commits1 - &commits0,
       &dbwn1 - &dbwn0,
       &sucios1
FROM dual
UNION ALL
SELECT '2. ALTER SYSTEM CHECKPOINT',
       ROUND((&redo2 - &redo1) / 1024),
       &lgwr2 - &lgwr1,
       &commits2 - &commits1,
       &dbwn2 - &dbwn1,
       &sucios2
FROM dual;

PROMPT Las cifras son de toda la instancia y pueden incluir actividad de fondo.
PROMPT COMMIT mueve redo con LGWR; CHECKPOINT mueve bloques con DBWn.
EXIT
