He leído la política de uso de IA de la asignatura.

# Declaración de uso de IA · Lab 6 · E055

### Entrada 1

**Herramienta:** ChatGPT.

**Prompt (literal, copiado tal cual):**
"continua con el lab 6 entonces". También he compartido capturas de pantalla de mi terminal para mostrar el progreso y permitir que ChatGPT identificase el punto del PDF en el que me encontraba.

**Código recibido (el fragmento, o la ruta del archivo donde está):**
No aplica

**Dónde lo usé (parte, script o pregunta):**
Parte A, preparación del entorno, configuración inicial y seguimiento de los apartados A.1 a A.6.

**Propósito (para qué lo necesitaba):**
Utilizar ChatGPT como guía para seguir el PDF paso a paso, resolver dudas y continuar la práctica desde el punto en el que me encontraba, utilizando capturas para mostrar mi progreso.

**Qué hace (con mis palabras; línea a línea si es SQL corto):**
ChatGPT me ayuda a identificar el siguiente apartado del PDF, comprender la finalidad de los comandos y resolver dudas durante la práctica. Yo realizo las operaciones y ejecuto los comandos siguiendo las instrucciones del documento.

**Evidencia de ejecución (spool o evidencia donde se ve ejecutado en tu contenedor):**
Los comandos propios de la práctica generan sus evidencias automáticamente en docs/bitacora/lab6/evidencia/. Los comandos auxiliares de Git y preparación del entorno no generan spools propios.

## Entrada 2 · Incidente INC-601

- **Herramienta:** ChatGPT.
- **Prompt (literal, copiado tal cual):** ayudame a resolver el bloqueo de la sesión de la aplicación.
- **Código recibido:**
  ```sql
  ALTER SYSTEM KILL SESSION '56,231' IMMEDIATE | docker exec -i oralab-26ai sqlplus -s / as sysdba
  ```
- **Dónde lo usé:** Parte I, incidente INC-601.
- **Propósito:** Liberar el bloqueo que impedía guardar la ficha del alumno 101.
- **Qué hace:** Finaliza la sesión identificada por SID 56 y SERIAL# 231.
- **Evidencia de ejecución:**  No se generó un archivo independiente; la ejecución se realizó desde el terminal Ubuntu y su resultado se mostró en pantalla.

## Entrada 3 · Incidente INC-603

- **Herramienta:** ChatGPT.
- **Prompt (literal, copiado tal cual):** ayudame para desbloquear la cuenta APP_ACADEMIA después de diagnosticar el error ORA-28000.
- **Código recibido:**
  ```sql
  ALTER SESSION SET CONTAINER = FREEPDB1;
  ALTER USER APP_ACADEMIA ACCOUNT UNLOCK;\n" | docker exec -i oralab-26ai sqlplus -s / as sysdba
  ```
- **Dónde lo usé:** Parte I, incidente INC-603.
- **Propósito:** Recuperar el acceso de la aplicación.
- **Qué hace:** Cambia al contenedor FREEPDB1 y desbloquea la cuenta APP_ACADEMIA sin cambiar su contraseña.
- **Evidencia de ejecución:**  No se generó un archivo independiente; la ejecución se realizó desde el terminal Ubuntu y su resultado se mostró en pantalla

## Entrada 4 — Consultas de configuración y busqueda de parametros necesarios

- **Herramienta:** ChatGPT
- **Prompt (literal, copiado tal cual):**
  ```text
  el 1. y el 4. de los archivos q me pides tienes q ser mas claro pq no entiendo q datos me faltan para poder responder todas las preguntas
  ```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
  ```bash
  grep -in 'processes' /opt/oracle/oradata/lab6/init_desde_spfile.ora

  cat /opt/oracle/oradata/lab6/init_desde_spfile.ora

  docker exec 6ec1054a2ab4 bash -lc "grep -in 'processes' /opt/oracle/oradata/lab6/init_desde_spfile.ora"
  ```
- **Dónde lo usé (parte, script o pregunta):** Comprobación de la configuración de Oracle para la pregunta 4 del apartado 9.
- **Propósito (para qué lo necesitaba):** localizar el parámetro `processes` en el PFILE y comprobar el valor original de configuración.
- **Qué hace (con mis palabras):** los dos primeros comandos intentan buscar y mostrar el PFILE desde Ubuntu. Como esa ruta no existía en el sistema anfitrión, utilicé `docker exec` para ejecutar la búsqueda dentro del contenedor de Oracle. Así pude consultar el parámetro sin modificar la configuración.
- **Evidencia de ejecución:** El primer intento desde Ubuntu devolvió que el archivo no existía; la consulta dentro del contenedor permitió localizar `processes=200`.

## Entrada 5 — Búsqueda y consulta de registros del laboratorio

- **Herramienta:** ChatGPT
- **Prompt (literal, copiado tal cual):**
  ```text
  vale algo mas para completar los datos necesarios para las preguntas?
  ```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
  ```bash
  find docs/bitacora -maxdepth 1 -type f | grep -Ei '08-|guardia'

  docker exec 6ec1054a2ab4 bash -lc "find /opt/oracle/diag -type f -name 'alert_*.log'"

  docker exec 6ec1054a2ab4 bash -lc "grep -in -B 3 -A 3 -E 'ORA-|carga-historico|statement.*(suspended|resumed)' /opt/oracle/diag/rdbms/free/FREE/trace/alert_FREE.log"
  ```
- **Dónde lo usé (parte, script o pregunta):** Comprobación de evidencias de los apartados 8 y 9, especialmente las preguntas 1, 13 y 20.
- **Propósito (para qué lo necesitaba):** localizar los registros de los incidentes de guardia y consultar el alert log para identificar errores ORA y los mensajes de suspensión y reanudación de una carga.
- **Qué hace (con mis palabras):** el primer comando busca archivos relacionados con la guardia dentro de la bitácora. El segundo localiza el alert log de Oracle dentro del contenedor. El tercero filtra ese registro para mostrar errores ORA y mensajes relacionados con la carga reanudable. Son consultas de lectura y no modifican la base de datos.
- **Evidencia de ejecución:** comando ejecutado en la terminal de ubuntu.




