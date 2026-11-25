-- V005: diseño definitivo de índices de TiendaSur (Lab 5, Parte G).
-- Idempotente: evita repetir la migración si ya existe UX_CLI_DNI.

SET FEEDBACK ON
ALTER SESSION SET CONTAINER = FREEPDB1;

WHENEVER SQLERROR EXIT SUCCESS
DECLARE
    n NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO n
    FROM dba_indexes
    WHERE owner = 'TIENDASUR'
      AND index_name = 'UX_CLI_DNI';

    IF n > 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'V005 ya aplicada: UX_CLI_DNI existe');
    END IF;
END;
/

WHENEVER SQLERROR EXIT SQL.SQLCODE

CREATE UNIQUE INDEX tiendasur.ux_cli_dni
    ON tiendasur.cliente (dni) ONLINE;

CREATE INDEX tiendasur.ix_ped_cli_fec_cub
    ON tiendasur.pedido (id_cliente, fecha_pedido, importe, estado, id_pedido) ONLINE;

DROP INDEX tiendasur.ix_ped_cliente;

ALTER TABLE tiendasur.pedido
    ADD (fecha_pendiente AS (CASE WHEN estado = 'P' THEN fecha_pedido END));

CREATE INDEX tiendasur.ix_ped_pendientes
    ON tiendasur.pedido (fecha_pendiente) ONLINE;

CREATE INDEX tiendasur.ix_ped_cp
    ON tiendasur.pedido (codigo_postal) ONLINE;

DROP INDEX tiendasur.ix_ped_importe;

SET LINESIZE 150 PAGESIZE 50
COLUMN table_name FORMAT A8
COLUMN index_name FORMAT A20

SELECT table_name, index_name, uniqueness, visibility
FROM dba_indexes
WHERE owner = 'TIENDASUR'
ORDER BY table_name, index_name;

EXIT
