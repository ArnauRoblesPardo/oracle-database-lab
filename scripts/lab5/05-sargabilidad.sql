WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 200 PAGESIZE 100 FEEDBACK OFF VERIFY OFF TAB OFF

ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON FORMAT WRAPPED

-- Comprobar que V005 aun no esta aplicada y limpiar restos anteriores.
DECLARE
  n NUMBER;
  PROCEDURE quitar(p_ddl VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE p_ddl;
  EXCEPTION WHEN OTHERS THEN NULL;
  END;
BEGIN
  SELECT COUNT(*) INTO n
    FROM dba_indexes
   WHERE owner = 'TIENDASUR'
     AND index_name = 'IX_PED_CLIENTE';

  IF n = 0 THEN
    RAISE_APPLICATION_ERROR(
      -20005,
      'V005 ya esta aplicada: este experimento es anterior'
    );
  END IF;

  quitar('DROP INDEX tiendasur.ix_ped_cp');
  quitar('DROP INDEX tiendasur.ix_cli_apellidos');
  quitar('DROP INDEX tiendasur.ix_cli_telefono');
END;
/

COLUMN tel NEW_VALUE tel NOPRINT
SELECT telefono AS tel
  FROM tiendasur.cliente
 WHERE id_cliente = 4711;

CREATE INDEX tiendasur.ix_ped_cp
  ON tiendasur.pedido (codigo_postal);

CREATE INDEX tiendasur.ix_cli_apellidos
  ON tiendasur.cliente (apellidos);

PROMPT ===== Regla 1: funcion sobre la columna =====
EXEC lab_tools.medir.consulta('Q1 rota', q'[SELECT id_cliente, nombre FROM tiendasur.cliente WHERE UPPER(email) = UPPER('Cliente4711@TiendaSur.es')]')
EXEC lab_tools.medir.consulta('Q1 reescrita', q'[SELECT id_cliente, nombre FROM tiendasur.cliente WHERE email = LOWER('Cliente4711@TiendaSur.es')]')

PROMPT ===== Regla 2: aritmetica sobre la columna =====
EXEC lab_tools.medir.consulta('Q2 rota', q'[SELECT id_pedido, importe FROM tiendasur.pedido WHERE fecha_pedido + INTERVAL '30' DAY >= CURRENT_DATE]')
EXEC lab_tools.medir.consulta('Q2 reescrita', q'[SELECT id_pedido, importe FROM tiendasur.pedido WHERE fecha_pedido >= CURRENT_DATE - INTERVAL '30' DAY]')

PROMPT ===== Regla 3: conversion implicita de tipos =====
EXEC lab_tools.medir.consulta('Q3 rota', q'[SELECT id_pedido, estado FROM tiendasur.pedido WHERE codigo_postal = 30001]')
EXEC lab_tools.medir.consulta('Q3 reescrita', q'[SELECT id_pedido, estado FROM tiendasur.pedido WHERE codigo_postal = '30001']')

SET SERVEROUTPUT OFF
SELECT /*+ GATHER_PLAN_STATISTICS */ COUNT(estado)
  FROM tiendasur.pedido
 WHERE codigo_postal = 30001;

SELECT plan_table_output
  FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT => 'BASIC +PREDICATE'))
 WHERE plan_table_output LIKE '%filter%'
    OR plan_table_output LIKE '%access%';

SET SERVEROUTPUT ON FORMAT WRAPPED

PROMPT ===== Regla 4: comodin a la izquierda =====
EXEC lab_tools.medir.consulta('Q4a LIKE %ez', q'[SELECT * FROM tiendasur.cliente WHERE apellidos LIKE '%ez']')
EXEC lab_tools.medir.consulta('Q4b LIKE Gonz%', q'[SELECT * FROM tiendasur.cliente WHERE apellidos LIKE 'Gonz%']')

PROMPT ===== Regla 5: OR con una columna sin indice =====
EXEC lab_tools.medir.consulta('Q5 OR sin indice en tel.', q'[SELECT * FROM tiendasur.cliente WHERE email = '&tel' OR telefono = '&tel']')

CREATE INDEX tiendasur.ix_cli_telefono
  ON tiendasur.cliente (telefono);

EXEC lab_tools.medir.consulta('Q5 OR con los dos indices', q'[SELECT * FROM tiendasur.cliente WHERE email = '&tel' OR telefono = '&tel']')
EXEC lab_tools.medir.consulta('Q5 como UNION', q'[SELECT * FROM tiendasur.cliente WHERE email = '&tel' UNION SELECT * FROM tiendasur.cliente WHERE telefono = '&tel']')

PROMPT ===== Bonus Q11: reescribir bien no obliga a usar el indice =====
EXEC lab_tools.medir.consulta('Q11 rota (EXTRACT)', q'[SELECT SUM(importe) FROM tiendasur.pedido WHERE EXTRACT(YEAR FROM fecha_pedido) = 2025]')
EXEC lab_tools.medir.consulta('Q11 reescrita (rango)', q'[SELECT SUM(importe) FROM tiendasur.pedido WHERE fecha_pedido >= DATE '2025-01-01' AND fecha_pedido < DATE '2026-01-01']')

PROMPT ===== Limpieza de indices temporales =====
DROP INDEX tiendasur.ix_ped_cp;
DROP INDEX tiendasur.ix_cli_apellidos;
DROP INDEX tiendasur.ix_cli_telefono;

SELECT COUNT(*) AS indices_tiendasur
  FROM dba_indexes
 WHERE owner = 'TIENDASUR';

EXIT
