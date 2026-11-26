#Preguntas de comprobación

### 1. ¿Cuántos errores ORA- tenía tu alert log en 24 h en la Parte B y a qué se debían? ¿Por qué ese número no es una alarma por sí solo?

En la comprobación de la Parte B aparecieron **2 errores ORA- en las últimas 24 horas**. Ese es el resultado que obtuve al consultar el alert log.

Para explicar la causa hay que distinguir el recuento de los mensajes concretos. En los registros posteriores aparecen errores `ORA-00800`, relacionados con el intento de Oracle de elevar la prioridad de los procesos `VKTM` y `LGWR`, que no pudo realizarse por las limitaciones del sistema operativo. También aparecen errores `ORA-65019` al intentar abrir una PDB que ya estaba abierta. Sin embargo, estos mensajes corresponden a una consulta posterior y no puedo asegurar que sean exactamente los dos errores del primer recuento.

El número de errores por sí solo no indica que exista una avería grave. Es necesario comprobar el código, la causa, la frecuencia y si ha tenido consecuencias sobre el funcionamiento de la base de datos.

### 2. ¿A qué hora empieza y cuánto dura la ventana de mantenimiento de un miércoles en tu base? ¿Qué tareas automáticas corren en ella?

La ventana `WEDNESDAY_WINDOW` empieza los miércoles a las **22:00** y tiene una duración de **4 horas**, por lo que termina a las 02:00 del jueves.

Durante ese periodo están habilitadas tres tareas automáticas: `auto optimizer stats collection`, que recopila estadísticas para el optimizador; `auto space advisor`, que analiza el uso del espacio; y `sql tuning advisor`, que analiza posibles mejoras en las consultas SQL.

### 3. Explica con tu salida de la Parte C la diferencia entre lo que mostraban V$SPPARAMETER y V$PARAMETER tras el SCOPE = SPFILE. ¿Qué habría pasado en el siguiente reinicio sin el RESET?

Al principio, `db_files` tenía el valor 200. Después ejecuté el cambio con `SCOPE=SPFILE` y establecí el valor en 250.

Al consultar las vistas, `V$SPPARAMETER` mostraba 250 porque refleja el valor guardado en el archivo SPFILE. En cambio, `V$PARAMETER` seguía mostrando 200, ya que representa el valor que estaba utilizando la instancia en ese momento.

Esto ocurre porque `db_files` es un parámetro estático y no se puede cambiar directamente en memoria. Si no hubiera ejecutado `RESET`, en el siguiente reinicio Oracle habría aplicado el valor 250 que estaba guardado en el SPFILE.

### 4. ¿Por qué RESET fue la vuelta atrás correcta para db_files y no lo habría sido para processes? Cita la línea de tu PFILE que lo demuestra.

Utilicé `RESET` con `db_files` porque comprobé que antes del cambio no estaba fijado explícitamente en el SPFILE (`ISSPECIFIED=FALSE`). Por tanto, eliminar esa entrada permitía que Oracle volviera a utilizar el valor predeterminado.

Con `processes` habría sido diferente, ya que en mi PFILE aparece establecido expresamente el valor 200. La línea que lo demuestra es:

`31*:processes=200`

En este caso no habría sido correcto utilizar `RESET`, porque habría eliminado el valor que estaba configurado originalmente. Lo adecuado habría sido restaurar el valor 200 de la copia de seguridad.

### 5. Tras el reinicio sin estado guardado, ¿qué error obtuvo C##OPS_RO y por qué la instancia decía «Database opened»?

Después del reinicio sin guardar el estado de la PDB, `FREEPDB1` quedó en estado `MOUNTED`. Al intentar acceder a ella, `C##OPS_RO` obtuvo el error **ORA-01109: database not open**.

El mensaje `Database opened` no significa que todas las PDB estén abiertas, sino que se refiere a la base de datos contenedora (CDB). En mi caso, la instancia estaba abierta, pero `FREEPDB1` seguía montada y no permitía acceder a la aplicación.

### 6. ¿Qué SID, SPID y evento tenía la sesión de la aplicación en tu ejecución? ¿Qué te dicen MODULE, ACTION y CLIENT_IDENTIFIER que no te diría USERNAME?

La sesión de la aplicación tenía estos datos:

- SID: 58.
- SERIAL#: 47893.
- SPID: 5624.
- Evento: `PL/SQL lock timer`.
- USERNAME: `APP_ACADEMIA`.
- SERVICE_NAME: `academia_app`.
- MODULE: `matriculas`.
- ACTION: `cierre-periodo`.
- CLIENT_IDENTIFIER: `ana.garcia@ucam`.

Con `USERNAME` solamente puedo saber qué cuenta está utilizando la conexión. Los otros campos permiten identificar mejor qué está haciendo la aplicación y quién ha iniciado la operación. En este caso, `MODULE` indica el módulo de matrículas, `ACTION` la operación de cierre de periodo y `CLIENT_IDENTIFIER` identifica a Ana García.

### 7. Tras CANCEL SQL, ¿cuántas transacciones abiertas tenía la aplicación? ¿Y tras KILL SESSION? ¿En qué estado quedó la fila 101 y por qué?

Después de ejecutar `CANCEL SQL`, la aplicación todavía tenía **una transacción abierta**. Cancelar la sentencia actual no significa necesariamente que se cierre la sesión ni que se deshaga toda la transacción.

Después ejecuté `KILL SESSION '58,47893' IMMEDIATE`. La sesión terminó y el número de sesiones activas de la aplicación pasó a cero.

La fila 101 quedó en estado `ACTIVO`, porque el cambio que se estaba realizando todavía no se había confirmado. Al terminar la sesión, Oracle deshizo la transacción pendiente mediante un rollback y recuperó el estado anterior de la fila.

### 8. ¿Qué valor tiene common_user_prefix en tu imagen? ¿Qué implica para el nombre de una cuenta común?

En mi imagen, el parámetro `common_user_prefix` aparece vacío. Esto significa que no se exige un prefijo concreto como `C##` para crear una cuenta común.

Por tanto, se pueden crear usuarios comunes sin tener que utilizar obligatoriamente ese prefijo en el nombre.

### 9. Completa con tus cifras la tabla de las tres miradas (ALL_TABLES, DBA_USERS, CDB_USERS, V$DATAFILE) y explica una diferencia.

Estos son los resultados que obtuve en las tres conexiones:

| Consulta | C##OPS_RO en CDB$ROOT | C##OPS_RO en FREEPDB1 | APP_ACADEMIA en FREEPDB1 |
|---|---:|---:|---:|
| ALL_TABLES de ADMIN_ACADEMIA | 0 | 0 | 1 |
| DBA_USERS | 37 | 47 | ORA-00942 |
| CDB_USERS | CON_ID 1: 37; CON_ID 3: 47 | CON_ID 3: 47 | ORA-00942 |
| V$DATAFILE | 17 | 10 | ORA-00942 |

Como información complementaria, `USER_TABLES` devolvió 0 en las tres conexiones y `ALL_USERS` mostró 37 usuarios desde la raíz y 47 desde la PDB.

La diferencia principal está en los permisos y en el contenedor desde el que se realizan las consultas. `C##OPS_RO` puede consultar información de varios contenedores desde la raíz porque tiene configurado `CONTAINER_DATA=ALL`. Desde `FREEPDB1`, en cambio, solo ve la información de esa PDB.

Por otro lado, `APP_ACADEMIA` puede consultar la tabla de `ADMIN_ACADEMIA` que tiene autorizada, pero no tiene permisos para consultar las vistas administrativas `DBA_USERS`, `CDB_USERS` y `V$DATAFILE`. Por eso obtiene `ORA-00942`.

### 10. Con tu salida de 04-deltas: ¿cuántas lecturas lógicas por recorrido y cuánto DB time costó la carga? ¿Qué indica la relación entre DB time y DB CPU?

En mi prueba obtuve **59.513 lecturas lógicas en 10 recorridos**, lo que supone una media aproximada de **5.951 lecturas lógicas por recorrido**.

El DB time de la carga fue de **0,32 segundos**, mientras que el DB CPU fue de **0,31 segundos**. Los dos valores son prácticamente iguales, por lo que casi todo el tiempo se empleó en trabajo de CPU y hubo muy poco tiempo dedicado a esperas.

### 11. Da las tres medidas (asignado, libre, máximo) de TBS_ACADEMIA_HIST antes de la carga y explica cuál usarías para alertar.

Antes de realizar la carga, `TBS_ACADEMIA_HIST` tenía:

- Espacio asignado: **10 MB**.
- Espacio libre: **3,9 MB**.
- Tamaño máximo: **40 MB**.

Para establecer una alerta tendría en cuenta el porcentaje ocupado respecto al máximo permitido, además del espacio libre actual. Esto es importante porque el tablespace puede crecer automáticamente y el espacio asignado no representa necesariamente su límite real.

### 12. ¿Quién insertó y quién «pagó» en el ORA-01950? ¿Por qué ampliar el tablespace no habría resuelto el ORA-01536?

En la primera prueba, la inserción se ejecutó desde la sesión administrativa, pero el segmento pertenecía al usuario `CARGA_HIST`. Por tanto, quien necesitaba disponer de cuota en `TBS_ACADEMIA_HIST` era el propietario del segmento.

Al no tener cuota asignada, apareció el error `ORA-01950`. Después le asigné una cuota de 2 MB y repetí la carga, pero esta vez apareció `ORA-01536` porque se superó esa cantidad.

Ampliar el tablespace no habría solucionado el problema, ya que no faltaba espacio físico en él, sino cuota para el usuario propietario. La solución fue ampliar la cuota de `CARGA_HIST` a 30 MB.

### 13. ¿Cuánto tiempo estuvo suspendida la carga reanudable y qué evidencia de ello dejó Oracle en el alert log?

La carga se configuró como reanudable con un tiempo máximo de espera de **180 segundos**. Cuando se superó la cuota de `TBS_ACADEMIA_HIST`, Oracle no canceló directamente la operación, sino que la dejó suspendida por el error `ORA-01536`.

En el alert log aparece primero el mensaje indicando que la sentencia `carga-historico` quedó suspendida y después otro indicando que se reanudó. Según las marcas temporales de la salida, la suspensión se produjo aproximadamente a las **07:40:57.641** y la reanudación a las **07:41:08.559**, por lo que estuvo suspendida unos **10,92 segundos**.

Después de ampliar la cuota del propietario a 30 MB, Oracle pudo continuar la operación y completar la inserción de las 20.000 filas.

### 14. Antes y después del SHRINK: filas, bloques y cuota consumida. ¿Por qué un DELETE no devolvió el espacio?

Antes de borrar datos, la tabla tenía **20.000 filas**, ocupaba **2.944 bloques** y consumía aproximadamente **23 MB de cuota**.

Después de eliminar 18.000 filas, quedaron 2.000 registros, pero el segmento seguía ocupando 2.944 bloques y consumiendo unos 23 MB. Esto ocurre porque `DELETE` elimina las filas, pero no reduce automáticamente el tamaño del segmento.

Después de ejecutar `SHRINK`, la tabla seguía teniendo 2.000 filas, pero pasó a ocupar **304 bloques** y aproximadamente **2,4 MB** de cuota. De esta forma, Oracle pudo recuperar el espacio que ya no necesitaba el segmento.

### 15. ¿Qué valores tenía tu perfil DEFAULT? Justifica dos de los límites de PRF_PERSONAS para una persona de secretaría.

Al consultar el perfil `DEFAULT` de mi base de datos obtuve estos valores:

| Parámetro | Valor |
|---|---|
| FAILED_LOGIN_ATTEMPTS | 10 |
| INACTIVE_ACCOUNT_TIME | 365 |
| PASSWORD_GRACE_TIME | 7 |
| PASSWORD_LIFE_TIME | 180 |
| PASSWORD_LOCK_TIME | 1 |
| PASSWORD_REUSE_MAX | UNLIMITED |
| PASSWORD_REUSE_TIME | UNLIMITED |
| PASSWORD_ROLLOVER_TIME | 0 |
| PASSWORD_VERIFY_FUNCTION | NULL |

Para la cuenta de una persona de secretaría configuré el perfil `PRF_PERSONAS`, con 3 intentos fallidos, un bloqueo de 1 minuto, una duración de contraseña de 90 días, 7 días de gracia y 90 días de inactividad. También utilicé la función `ORA12C_VERIFY_FUNCTION` para comprobar la complejidad de las contraseñas.

Me parecen especialmente importantes los 3 intentos fallidos, porque reducen el riesgo de que alguien pruebe muchas contraseñas hasta conseguir acceder a la cuenta. También considero importante la duración de 90 días, ya que obliga a renovar periódicamente las credenciales. El bloqueo de un minuto es una configuración específica de este laboratorio y no necesariamente la que utilizaría en un entorno real.

### 16. ¿Por qué Ana pudo leer ACA_MATRICULAS si nadie se la concedió por nombre? ¿Qué error obtuvo al cambiar el nombre de un alumno?

Ana podía consultar `ACA_MATRICULAS` porque tenía asignado el rol `ROL_SECRETARIA_ACADEMIA`, que heredaba los permisos de `ROL_LECTURA_ACADEMIA`. Este último tenía el privilegio `SELECT ANY TABLE ON SCHEMA ADMIN_ACADEMIA`, por lo que podía consultar las tablas de ese esquema sin necesitar una concesión individual para cada una.

Sin embargo, al intentar modificar el nombre de un alumno obtuvo el error **ORA-41900: missing UPDATE privilege**. Esto se debe a que su permiso de actualización estaba limitado a la columna `ESTADO`. Podía consultar los datos y cambiar el estado de los alumnos, pero no modificar sus nombres.

### 17. ¿Qué objetos se invalidaron en cada uno de los tres cambios de columna y por qué no se invalidó nada con la columna nueva?

Al principio, la función `F_TOTAL_ACTIVOS_LAB6` y las vistas `V_ACTIVOS_LAB6` y `V_CONTACTO_LAB6` aparecían como `VALID`.

Cuando añadí una columna nueva que no utilizaban los objetos existentes, ninguno se invalidó. Sin embargo, al ampliar la columna `email_institucional`, la vista `V_CONTACTO_LAB6` pasó a estar `INVALID`.

Después, al ampliar la columna `nombres`, quedaron invalidados la función `F_TOTAL_ACTIVOS_LAB6` y las dos vistas. Esto se debe a que esos objetos dependen de la tabla y de las columnas modificadas. Finalmente, realicé las recompilaciones correspondientes y la comprobación terminó sin objetos de negocio inválidos.

### 18. Según tus advisors, ¿mejoraría el DB time duplicar la SGA? ¿Y por debajo de qué tamaño la PGA tendría sobreasignaciones?

Según los resultados del asesor de SGA, aumentar la memoria de **1.536 MB a 3.072 MB** no suponía una mejora estimada del DB time, ya que el factor de mejora era 1.

En cuanto a la PGA, con **128 MB y 256 MB** aparecían 5 sobreasignaciones. Al probar con **384 MB**, dejaron de aparecer. Por tanto, en mi prueba el tamaño a partir del cual desaparecían las sobreasignaciones fue 384 MB. Esto es el resultado de mi entorno de laboratorio, no un valor universal para todas las bases de datos.

### 19. ¿Cuántas lecturas lógicas necesitó la consulta de la aplicación según la traza (o tkprof)? ¿Qué línea de la traza lo dice?

La consulta de la aplicación necesitó **247 lecturas lógicas**. En la salida de `tkprof` aparecía `FETCH query=247`, con `disk=0`.

La línea de la traza que lo demuestra es la correspondiente a `FETCH`, donde aparece `p=0, cr=247`. El valor `cr` representa las lecturas lógicas y `p` las lecturas físicas. Por tanto, se realizaron 247 lecturas lógicas y ninguna física.

### 20. Para cada incidente de la guardia: evidencia clave, intervención y validación (una línea por cada uno).

- **INC-601 – Bloqueo al guardar la ficha de un alumno:** La sesión SID 56 de `APP_ACADEMIA`, con módulo `matriculas` y acción `cierre-periodo`, bloqueaba a la sesión SID 65 de `ANA_GARCIA` al acceder a la fila 101 de `ACA_ESTUDIANTES`; ejecuté `ALTER SYSTEM KILL SESSION '56,231' IMMEDIATE` para terminar la sesión bloqueadora y liberar el bloqueo, y comprobé la recuperación de la operación de la aplicación.

- **INC-602 – Servicio de aplicación no anunciado por el listener:** Comprobé que `FREEPDB1` estaba abierta, pero que `academia_app` no estaba activo ni anunciado por el listener; ejecuté el procedimiento de arranque del servicio mediante `DBMS_SERVICE.START_SERVICE` y guardé su estado para futuros reinicios. Después comprobé que el listener anunciaba `academia_app` y `freepdb1` en estado `READY`.

- **INC-603 – Cuenta de aplicación bloqueada:** Al investigar el error `ORA-28000`, comprobé que `APP_ACADEMIA` estaba en estado `LOCKED`, no `LOCKED(TIMED)`, y que utilizaba el perfil `DEFAULT`; cambié al contenedor `FREEPDB1` y ejecuté `ALTER USER APP_ACADEMIA ACCOUNT UNLOCK`. Al repetir el diagnóstico, la cuenta dejó de aparecer entre las cuentas bloqueadas.
