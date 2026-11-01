-- scripts/lab4/09-procesos.sql
-- H.1: Procesos de background y procesos servidor (SQLcl · C##OPS_RO · servicio FREE)

@scripts/ops/marca
SPOOL docs/bitacora/lab4/evidencia/spool/&marca._09-procesos.spool.log

SET SQLFORMAT DEFAULT
SET LINESIZE 180 PAGESIZE 100 FEEDBACK OFF

COLUMN pname FORMAT A6
COLUMN spid FORMAT A8
COLUMN description FORMAT A48
COLUMN program FORMAT A34
COLUMN tipo FORMAT A11
COLUMN username FORMAT A12
COLUMN machine FORMAT A14

PROMPT
PROMPT == 1. Cuantos procesos tiene la instancia y de que tipo ==

SELECT CASE WHEN background = '1' THEN 'background' ELSE 'servidor' END AS tipo,
       COUNT(*) AS procesos_oracle,
       COUNT(DISTINCT spid) AS procesos_linux
FROM v$process
WHERE spid IS NOT NULL
GROUP BY CASE WHEN background = '1' THEN 'background' ELSE 'servidor' END;

PROMPT (si procesos_oracle > procesos_linux: algunos procesos Oracle son hilos dentro de un mismo proceso Linux)
PROMPT
PROMPT == 2. Procesos obligatorios y relevantes para el examen ==

SELECT b.name AS pname, p.spid, b.description
FROM v$bgprocess b
JOIN v$process p ON p.addr = b.paddr
WHERE b.name IN (
  'PMON', 'LREG', 'SMON', 'DBW0', 'LGWR', 'CKPT', 'MMON', 'MMNL',
  'RECO', 'CJQ0', 'DIAG', 'DIA0', 'VKTM', 'PMAN', 'CLMN', 'PSP0',
  'MMAN', 'ARC0'
)
ORDER BY CASE b.name
  WHEN 'PMON' THEN 1
  WHEN 'LREG' THEN 2
  WHEN 'SMON' THEN 3
  WHEN 'DBW0' THEN 4
  WHEN 'LGWR' THEN 5
  WHEN 'CKPT' THEN 6
  WHEN 'MMON' THEN 7
  WHEN 'MMNL' THEN 8
  WHEN 'RECO' THEN 9
  ELSE 10
END, b.name;

PROMPT
PROMPT == 3. Hay archivadores ARCn? ==

SELECT COUNT(*) AS procesos_arcn
FROM v$bgprocess
WHERE name LIKE 'ARC%'
  AND paddr <> '00';

PROMPT
PROMPT == 4. Mi sesion y el proceso servidor que la atiende ==

SELECT s.sid, s.serial#, s.username, s.machine, s.program, p.spid
FROM v$session s
JOIN v$process p ON p.addr = s.paddr
WHERE s.sid = SYS_CONTEXT('USERENV', 'SID');

PROMPT
PROMPT == 5. Todas las sesiones de usuario ahora mismo ==

SELECT s.sid, s.username, s.status, s.machine, s.program, p.spid
FROM v$session s
JOIN v$process p ON p.addr = s.paddr
WHERE s.type = 'USER'
ORDER BY s.sid;

SPOOL OFF
EXIT
