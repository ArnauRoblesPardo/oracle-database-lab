-- database/migrations/V004__banco_tiendasur.sql
-- Lab 5 - Banco de pruebas TiendaSur
-- Migracion versionada e idempotente.
-- Datos deterministas mediante ORA_HASH. Sin DBMS_RANDOM.

WHENEVER SQLERROR EXIT SQL.SQLCODE

ALTER SESSION SET CONTAINER = FREEPDB1;

SET SERVEROUTPUT ON
SET FEEDBACK ON
SET LINESIZE 160

PROMPT ==========================================
PROMPT V004 - BANCO DE PRUEBAS TIENDASUR
PROMPT ==========================================

-- 1. Tablespace BIGFILE de 256 MB, ampliable hasta 2 GB.

DECLARE
    n NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO n
      FROM dba_tablespaces
     WHERE tablespace_name = 'TBS_TIENDASUR';

    IF n = 0 THEN
        EXECUTE IMMEDIATE q'[
            CREATE BIGFILE TABLESPACE TBS_TIENDASUR
            DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/tiendasur01.dbf'
            SIZE 256M
            AUTOEXTEND ON NEXT 64M MAXSIZE 2G
        ]';
        DBMS_OUTPUT.PUT_LINE('Tablespace TBS_TIENDASUR creado.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Tablespace TBS_TIENDASUR ya existe.');
    END IF;
END;
/

-- 2. Esquema propietario sin contraseña.

DECLARE
    n NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO n
      FROM dba_users
     WHERE username = 'TIENDASUR';

    IF n = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE USER TIENDASUR NO AUTHENTICATION
             DEFAULT TABLESPACE TBS_TIENDASUR
             QUOTA UNLIMITED ON TBS_TIENDASUR';

        DBMS_OUTPUT.PUT_LINE('Usuario TIENDASUR creado.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Usuario TIENDASUR ya existe.');
    END IF;
END;
/

-- 3. Tabla CLIENTE.

DECLARE
    n NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO n
      FROM dba_tables
     WHERE owner = 'TIENDASUR'
       AND table_name = 'CLIENTE';

    IF n = 0 THEN
        EXECUTE IMMEDIATE q'[
            CREATE TABLE TIENDASUR.CLIENTE (
                id_cliente INTEGER NOT NULL,
                dni        CHAR(9) NOT NULL,
                email      VARCHAR2(120) NOT NULL,
                nombre     VARCHAR2(60) NOT NULL,
                apellidos  VARCHAR2(80) NOT NULL,
                telefono   VARCHAR2(15),
                pais       CHAR(2) NOT NULL,
                ciudad     VARCHAR2(60) NOT NULL,
                fecha_alta DATE NOT NULL,
                CONSTRAINT pk_cli PRIMARY KEY (id_cliente)
            ) TABLESPACE TBS_TIENDASUR
        ]';
    END IF;
END;
/

-- 4. Tabla PEDIDO.

DECLARE
    n NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO n
      FROM dba_tables
     WHERE owner = 'TIENDASUR'
       AND table_name = 'PEDIDO';

    IF n = 0 THEN
        EXECUTE IMMEDIATE q'[
            CREATE TABLE TIENDASUR.PEDIDO (
                id_pedido    NUMBER(19) NOT NULL,
                id_cliente   INTEGER NOT NULL,
                fecha_pedido TIMESTAMP NOT NULL,
                estado       CHAR(1) NOT NULL,
                importe      NUMBER(12,2) NOT NULL,
                canal        CHAR(1) NOT NULL,
                codigo_postal VARCHAR2(5) NOT NULL,
                CONSTRAINT pk_ped PRIMARY KEY (id_pedido),
                CONSTRAINT fk_ped_cliente
                    FOREIGN KEY (id_cliente)
                    REFERENCES TIENDASUR.CLIENTE(id_cliente),
                CONSTRAINT ck_ped_estado
                    CHECK (estado IN ('P','E','C','D'))
            ) TABLESPACE TBS_TIENDASUR
        ]';
    END IF;
END;
/

-- 5. Carga determinista de 100.000 clientes.
-- 60,1 % España; 0,1 % Lorca; 2,1 % apellidos Gonz...

DECLARE
    n NUMBER;
BEGIN
    SELECT COUNT(*) INTO n FROM TIENDASUR.CLIENTE;

    IF n = 0 THEN
        INSERT /*+ APPEND */ INTO TIENDASUR.CLIENTE
        (
            id_cliente, dni, email, nombre, apellidos,
            telefono, pais, ciudad, fecha_alta
        )
        SELECT
            x,
            LPAD(TO_CHAR(x), 8, '0') || 'A',
            'cliente' || TO_CHAR(x) || '@tiendasur.es',
            CASE MOD(ORA_HASH(x, 99), 5)
                WHEN 0 THEN 'Ana'
                WHEN 1 THEN 'Luis'
                WHEN 2 THEN 'Maria'
                WHEN 3 THEN 'Carlos'
                ELSE 'Laura'
            END,
            CASE
                WHEN MOD(ORA_HASH(x, 9999), 10000) < 210
                    THEN 'Gonzalez'
                ELSE 'Garcia'
            END,
            '6' || LPAD(TO_CHAR(MOD(x, 100000000)), 8, '0'),
            CASE
                WHEN MOD(ORA_HASH(x, 9999), 10000) < 6010
                    THEN 'ES'
                ELSE 'FR'
            END,
            CASE
                WHEN MOD(ORA_HASH(x, 999), 1000) = 0
                    THEN 'Lorca'
                ELSE 'Sevilla'
            END,
            DATE '2023-01-01' + MOD(ORA_HASH(x, 9999), 1095)
        FROM (
            SELECT LEVEL x
            FROM dual
            CONNECT BY LEVEL <= 100000
        )
        ORDER BY x;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Clientes insertados: 100000');
    ELSE
        DBMS_OUTPUT.PUT_LINE('CLIENTE ya contiene datos; no se repite la carga.');
    END IF;
END;
/

-- 6. Carga determinista de 1.000.000 de pedidos.
-- Fecha correlacionada con id_pedido.
-- id_cliente distribuido mediante ORA_HASH.
-- Estados: P 2 %, E 5 %, C 90,2 %, D 2,8 %.

DECLARE
    n NUMBER;
BEGIN
    SELECT COUNT(*) INTO n FROM TIENDASUR.PEDIDO;

    IF n = 0 THEN
        INSERT /*+ APPEND */ INTO TIENDASUR.PEDIDO
        (
            id_pedido, id_cliente, fecha_pedido,
            estado, importe, canal, codigo_postal
        )
        SELECT
            x,
            MOD(ORA_HASH(x, 99999), 100000) + 1,
            TIMESTAMP '2023-01-01 00:00:00'
                + NUMTODSINTERVAL((x - 1) * 94.608, 'SECOND'),
            CASE
                WHEN x > 980000 THEN 'P'
                WHEN x > 930000 THEN 'E'
                WHEN x <= 28000 THEN 'D'
                ELSE 'C'
            END,
            ROUND(10 + MOD(ORA_HASH(x, 999999), 100000) / 100, 2),
            CASE MOD(ORA_HASH(x, 99), 3)
                WHEN 0 THEN 'W'
                WHEN 1 THEN 'A'
                ELSE 'T'
            END,
            LPAD(TO_CHAR(MOD(ORA_HASH(x, 99999), 11000)), 5, '0')
        FROM (
            SELECT LEVEL x
            FROM dual
            CONNECT BY LEVEL <= 1000000
        )
        ORDER BY x;

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Pedidos insertados: 1000000');
    ELSE
        DBMS_OUTPUT.PUT_LINE('PEDIDO ya contiene datos; no se repite la carga.');
    END IF;
END;
/

-- 7. Índices heredados de la Actividad 3.2.

DECLARE
    n NUMBER;
BEGIN
    SELECT COUNT(*) INTO n FROM dba_indexes
     WHERE owner = 'TIENDASUR' AND index_name = 'UX_CLI_EMAIL';
    IF n = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE UNIQUE INDEX TIENDASUR.ux_cli_email ON TIENDASUR.CLIENTE(email)';
    END IF;

    SELECT COUNT(*) INTO n FROM dba_indexes
     WHERE owner = 'TIENDASUR' AND index_name = 'IX_CLI_PAIS_CIUDAD';
    IF n = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE INDEX TIENDASUR.ix_cli_pais_ciudad ON TIENDASUR.CLIENTE(pais, ciudad)';
    END IF;

    SELECT COUNT(*) INTO n FROM dba_indexes
     WHERE owner = 'TIENDASUR' AND index_name = 'IX_PED_CLIENTE';
    IF n = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE INDEX TIENDASUR.ix_ped_cliente ON TIENDASUR.PEDIDO(id_cliente)';
    END IF;

    SELECT COUNT(*) INTO n FROM dba_indexes
     WHERE owner = 'TIENDASUR' AND index_name = 'IX_PED_FECHA';
    IF n = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE INDEX TIENDASUR.ix_ped_fecha ON TIENDASUR.PEDIDO(fecha_pedido)';
    END IF;

    SELECT COUNT(*) INTO n FROM dba_indexes
     WHERE owner = 'TIENDASUR' AND index_name = 'IX_PED_IMPORTE';
    IF n = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE INDEX TIENDASUR.ix_ped_importe ON TIENDASUR.PEDIDO(importe)';
    END IF;
END;
/

-- 8. Estadísticas e histogramas.

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname => 'TIENDASUR',
        tabname => 'CLIENTE',
        estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
        method_opt => 'FOR COLUMNS pais SIZE 254
                       FOR COLUMNS ciudad SIZE 254
                       FOR COLUMNS apellidos SIZE 254',
        cascade => TRUE
    );

    DBMS_STATS.GATHER_TABLE_STATS(
        ownname => 'TIENDASUR',
        tabname => 'PEDIDO',
        estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
        method_opt => 'FOR COLUMNS estado SIZE 254
                       FOR COLUMNS canal SIZE 254',
        cascade => TRUE
    );
END;
/

-- 9. Verificación final.

PROMPT === FILAS DEL BANCO TIENDASUR ===

SELECT 'CLIENTE' tabla, COUNT(*) filas
FROM TIENDASUR.CLIENTE
UNION ALL
SELECT 'PEDIDO', COUNT(*)
FROM TIENDASUR.PEDIDO;

PROMPT === DISTRIBUCION DE ESTADOS ===

SELECT estado,
       COUNT(*) filas,
       ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER (), 2) porcentaje
FROM TIENDASUR.PEDIDO
GROUP BY estado
ORDER BY estado;

PROMPT === SESGO DE CLIENTES ===

SELECT
    ROUND(100 * SUM(CASE WHEN pais = 'ES' THEN 1 ELSE 0 END)
          / COUNT(*), 2) porcentaje_espana,
    SUM(CASE WHEN ciudad = 'Lorca' THEN 1 ELSE 0 END) clientes_lorca,
    ROUND(100 * SUM(CASE WHEN apellidos LIKE 'Gonz%' THEN 1 ELSE 0 END)
          / COUNT(*), 2) porcentaje_gonz
FROM TIENDASUR.CLIENTE;

PROMPT === INDICES ===

SELECT index_name, uniqueness
FROM dba_indexes
WHERE owner = 'TIENDASUR'
ORDER BY index_name;

PROMPT === V004 FINALIZADA ===

EXIT
