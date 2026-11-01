# Laboratorio 4 — Oracle DBA Workflow I
## Respuestas de comprobación y preguntas tipo examen

> **Antes de entregar:** sustituye los campos entre corchetes por los valores exactos de tus evidencias. No inventes el nombre/fecha de la copia ni el tiempo de restauración. Las rutas de evidencia deben existir en `docs/bitacora/lab4/evidencia/`.

## 8. Preguntas de comprobación

### 1. ¿Por qué la copia de la Parte B es consistente? ¿Qué pasaría si se tomara con la base abierta?
Es consistente porque el script ejecuta `SHUTDOWN IMMEDIATE` antes de copiar el volumen: Oracle cierra la base limpiamente y deja los archivos sincronizados. Así, al restaurar, no se necesita recuperar transacciones incompletas con redo. Si se copiara con la base abierta, los datafiles, control files y redo podrían corresponder a momentos distintos y la copia podría ser inconsistente.

**Evidencia:** `evidencia/script/*_00-backup-lab3.script.log`; `backups/[carpeta]_lab3-final/manifiesto.txt` (campo `tipo=copia en frio consistente`).

### 2. ¿Para qué sirven `manifiesto.txt` y `SHA256SUMS`? ¿Qué comprueba `restaurar-estado.sh` antes de tocar nada?
`manifiesto.txt` identifica la copia: etiqueta, fecha UTC, contenedor, volumen, imagen, commit, tipo y número de archivos externos. `SHA256SUMS` contiene huellas SHA-256 para detectar modificaciones o corrupción. Antes de alterar el volumen, `restaurar-estado.sh` ejecuta `sha256sum --check --quiet SHA256SUMS`; si la integridad falla, el script se detiene antes de borrar o restaurar datos.

**Evidencia:** `backups/[carpeta]_lab3-final/manifiesto.txt` y `backups/[carpeta]_lab3-final/SHA256SUMS`; salida de `sha256sum --check SHA256SUMS`.

### 3. Define RPO y RTO con los datos de tu propia copia.
RPO (*Recovery Point Objective*) es la cantidad máxima de datos que se acepta perder, es decir, el trabajo realizado desde el punto de copia. En esta práctica, la copia se identificó como **[etiqueta y fecha de manifiesto]**; por tanto, el RPO medido se expresa como el intervalo entre esa copia y el momento del incidente: **[indicar intervalo según los datos reales]**. RTO (*Recovery Time Objective*) es el tiempo necesario para recuperar el servicio. En mi prueba, el tiempo desde el inicio de la restauración hasta que la instancia y la PDB quedaron disponibles fue **[medir o indicar “no medido en Lab 4” si no se hizo la restauración]**.

**Evidencia:** `manifiesto.txt` (campo `fecha_utc`); si no se ejecutó una restauración cronometrada, no afirmar un RTO medido.

### 4. ¿Dónde creó Oracle los datafiles de V000 y por qué? ¿Qué parámetro habría evitado el problema?
V000 usó nombres relativos, como `academia01.dbf`, sin fijar un destino OMF. Oracle los resolvió bajo `$ORACLE_HOME/dbs`, por ejemplo `/opt/oracle/product/26ai/dbhomeFree/dbs/academia01.dbf`, en lugar de la carpeta persistente estándar de `FREEPDB1`. Configurar `DB_CREATE_FILE_DEST` con un destino adecuado habría permitido que Oracle creara los archivos en una ubicación administrada y persistente.

**Evidencia:** `evidencia/script/*_01-diagnostico.script.log`; `evidencia/script/*_03-reubicar-datafiles.script.log`.

### 5. ¿Por qué `ALTER TABLESPACE ... RENAME DATAFILE` no basta para mover un archivo?
La sentencia solo cambia en el control file la ruta registrada para el datafile; no copia ni mueve los bytes del archivo en el sistema operativo. Hay que copiar primero el archivo a la nueva ruta, actualizar la ruta en Oracle con el tablespace fuera de línea, volverlo a poner `ONLINE` y comprobar que Oracle puede abrirlo. En este laboratorio se utilizó el método offline porque Oracle Database Free no admite `ALTER DATABASE MOVE DATAFILE` en línea.

**Evidencia:** `evidencia/script/*_03-reubicar-datafiles.script.log`.

### 6. ¿Por qué no se edita V000 y se crea V003? ¿Por qué invalidar una contraseña es mejor que borrarla del archivo?
Una migración ya aplicada es parte del historial y editarla haría que distintos entornos pudieran terminar con estados diferentes. La corrección debe añadirse en una nueva migración, V003. Además, borrar una contraseña del archivo actual no la elimina de los commits históricos; invalidarla mediante `NO AUTHENTICATION` hace que la credencial expuesta deje de servir.

**Evidencia:** `database/migrations/V003__cuentas_esquema_sin_password.sql`; evidencia de V003 y consulta de `DBA_USERS` con `AUTHENTICATION_TYPE = NONE`.

### 7. ¿Qué demuestra la prueba de persistencia y por qué se ejecuta después de reubicar?
Demuestra que, al detener y borrar el contenedor y recrearlo usando el mismo volumen, siguen existiendo los tablespaces, tablas y datos de negocio. Se ejecuta después de reubicar los datafiles porque, si alguno continuara en la capa efímera del contenedor, `docker rm` podría eliminarlo y provocar pérdida de datos.

**Evidencia:** `evidencia/script/*_03-prueba-persistencia.script.log`; comparar las secciones “ANTES” y “DESPUÉS”.

### 8. Con tus evidencias: tres datos que pertenecen a la instancia y tres que pertenecen a la base de datos.
**Instancia:** nombre/estado de instancia (`V$INSTANCE.STATUS`), hora de arranque (`V$INSTANCE.STARTUP_TIME`) y memoria SGA/PGA (`V$SGA`, `V$PGASTAT`). La instancia es el conjunto de memoria y procesos que existe mientras está arrancada.  
**Base de datos:** DBID, modo de apertura/registro (`V$DATABASE.OPEN_MODE`, `LOG_MODE`) y archivos físicos (datafiles, control files y redo logs). Los archivos persisten aunque la instancia se apague.

**Evidencia:** `evidencia/spool/*_05-instancia-y-base.spool.log`; `evidencia/script/*_05-instancia-so.script.log`; `evidencia/spool/*_08-memoria.spool.log`.

### 9. ¿Qué lee Oracle en NOMOUNT, MOUNT y OPEN? Relaciónalo con ORA-01507 y ORA-01219.
En `NOMOUNT`, Oracle lee el SPFILE/PFILE, reserva la SGA y arranca los procesos; todavía no ha abierto el control file. Por eso `V$PARAMETER` responde, pero consultar `V$DATABASE` puede dar ORA-01507. En `MOUNT`, abre los control files y conoce datafiles/redo, pero los datafiles de la base aún no están abiertos; las consultas al diccionario como `DBA_TABLES` dan ORA-01219. En `OPEN`, abre datafiles y redo y permite el acceso normal al diccionario.

**Evidencia:** `evidencia/script/*_06-arranque-por-etapas.script.log`.

### 10. ¿Por qué FREEPDB1 se abre sola tras ALTER DATABASE OPEN? ¿Qué harías si no lo hiciera?
Porque su estado de apertura quedó guardado con `ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE`, que Oracle registra en `DBA_PDB_SAVED_STATES`. Si no se abriera, comprobaría `V$PDBS`; la abriría con `ALTER PLUGGABLE DATABASE FREEPDB1 OPEN` y guardaría el estado con `ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE`.

**Evidencia:** `evidencia/script/*_06-arranque-por-etapas.script.log`, consulta de `DBA_PDB_SAVED_STATES`.

### 11. Clasifica ORA-00800 y ORA-20013 del alert log: ¿alerta real o ruido conocido? Justifícalo.
En este entorno son avisos conocidos, no fallos que impidan funcionar a la base. ORA-00800 indica que el contenedor no permitió a Oracle cambiar la prioridad de un proceso (por ejemplo, VKTM/LGWR) porque no dispone de la capacidad del sistema operativo correspondiente. ORA-20013, asociado a `DBMS_QOPATCH`, indica que el inventario de parches no puede leerse en esta imagen de contenedor. Deben documentarse y distinguirse de otros errores ORA que sí requieren investigación.

**Evidencia:** `evidencia/script/*_06-alert-log.script.log`.

### 12. Diferencia entre V$PARAMETER y V$SPPARAMETER con el ejemplo de DB_FILES.
`V$PARAMETER` muestra el valor efectivo que usa la instancia en memoria. `V$SPPARAMETER` muestra los valores especificados en el SPFILE y si existe una entrada persistente. En la prueba, `DB_FILES` conservó el valor efectivo 200; al probar 300 con `SCOPE=SPFILE`, la entrada quedó pendiente, y `ALTER SYSTEM RESET DB_FILES SCOPE=SPFILE` la eliminó. Por eso al final la verificación indica que no queda una entrada especificada.

**Evidencia:** `evidencia/script/*_07-parametros-cambios.script.log`; `evidencia/spool/*_07-parametros-lectura.spool.log`.

### 13. ¿Qué hace SCOPE=BOTH y cuál es el SCOPE por defecto con SPFILE?
`SCOPE=BOTH` aplica el cambio al valor en memoria y lo escribe también en el SPFILE, de modo que se mantiene tras reiniciar. Cuando la instancia se ha arrancado con SPFILE, el alcance por defecto de `ALTER SYSTEM SET` es `BOTH`. Con PFILE, el valor por defecto es `MEMORY`, porque no hay SPFILE donde persistir el cambio.

**Evidencia:** `evidencia/script/*_07-parametros-cambios.script.log`.

### 14. ¿Por qué PROCESSES rechaza el cambio en memoria aunque V$PARAMETER lo marque IMMEDIATE?
Aunque `V$PARAMETER.ISSYS_MODIFIABLE` muestre `IMMEDIATE`, en la versión de Oracle de este laboratorio el cambio de `PROCESSES` en memoria se rechaza con ORA-02095 porque dimensiona estructuras de la instancia que se reservan al arrancar. Debe configurarse con `SCOPE=SPFILE` y aplicarse en un reinicio planificado.

**Evidencia:** `evidencia/script/*_07-parametros-cambios.script.log` (ORA-02095 esperado).

### 15. ¿Para qué sirve versionar el PFILE? Explica “configuration drift”.
El PFILE es una representación legible de la configuración de arranque. Versionarlo permite comparar cambios con `git diff`, recuperar una configuración conocida y detectar *configuration drift*: diferencias entre la configuración real y la documentada o aprobada. También sirve como alternativa para arrancar si un SPFILE mal configurado impide iniciar la instancia.

**Evidencia:** `evidencia/config/initFREE_lab4.ora`, `evidencia/config/initFREE_lab4_memoria.ora` y `evidencia/script/*_07-pfile.script.log`.

### 16. ¿Qué modelo de gestión de memoria usa tu instancia? Justifícalo con tres parámetros.
La instancia usa ASMM (*Automatic Shared Memory Management*): `MEMORY_TARGET=0` y `MEMORY_SIZE=0` indican que no está activa la gestión automática conjunta de SGA y PGA; `SGA_TARGET=1536M` establece el objetivo de la SGA, y `PGA_AGGREGATE_TARGET=512M` gestiona la PGA por separado. Los componentes de la SGA se redistribuyen dinámicamente dentro del objetivo.

**Evidencia:** `evidencia/spool/*_08-memoria.spool.log`. Confirmar los valores efectivos exactos de esa salida.

### 17. Explica las cifras de tu experimento de caché: lecturas lógicas, físicas y tasa de acierto.
En mi ejecución, la ronda fría registró **355 lecturas lógicas y 261 físicas**; la ronda caliente, **247 lecturas lógicas y 0 físicas**. La segunda ronda pudo reutilizar los bloques que ya estaban en el Buffer Cache, por lo que no necesitó lecturas físicas. La tasa de acierto de la ronda caliente es `1 − físicas/lógicas = 1 − 0/247 = 100 %`. Las lecturas lógicas pueden variar entre rondas si hay actividad o diferencias en la consulta; lo esencial es que la segunda ronda tuvo cero lecturas físicas.

**Evidencia:** `evidencia/script/*_08-experimento-cache.script.log`. Revisar que los valores citados coincidan con la salida guardada.

### 18. ¿Por qué no se suma el RSS de los procesos para saber la memoria de la instancia?
Porque los procesos de Oracle comparten la SGA y el RSS puede contabilizar páginas compartidas en cada proceso. Sumar esos RSS cuenta repetidamente la misma memoria y sobreestima el consumo real. Para medir la memoria de Oracle se deben consultar `V$SGA` y `V$PGASTAT` o usar `docker stats` para el consumo del contenedor.

**Evidencia:** `evidencia/script/*_05-instancia-so.script.log`; `evidencia/spool/*_08-memoria.spool.log`.

### 19. Relaciona el SPID de LGWR de V$PROCESS con el PID de /proc. ¿Por qué docker top muestra otro número?
`V$PROCESS.SPID` corresponde al PID que Oracle ve dentro del contenedor. El script `09-procesos-so.sh` lee `/proc` dentro de ese mismo contenedor, por lo que el PID debe coincidir con el SPID de LGWR obtenido en `09-procesos.sql`. `docker top`, en cambio, muestra el PID del anfitrión, porque se encuentra en otro espacio de nombres de PID.

**Evidencia:** `evidencia/spool/*_09-procesos.spool.log`; `evidencia/script/*_09-procesos-so.script.log`. Inserta el SPID real de LGWR de tu salida: **[SPID]**.

### 20. ¿Qué hace PMON y qué hace SMON? Pon un ejemplo de cada uno.
PMON limpia procesos de usuario caídos: deshace la transacción abandonada y libera sus bloqueos; por ejemplo, cuando se apaga el equipo de un usuario durante un `UPDATE`. SMON realiza recuperación de instancia al arrancar tras una caída y limpia segmentos temporales. No son intercambiables: PMON trata la limpieza de procesos y SMON la recuperación de instancia.

**Evidencia:** `evidencia/spool/*_09-procesos.spool.log`.

### 21. ¿Por qué C##OPS_RO y no SYSTEM para observar? ¿Qué no puede hacer C##OPS_RO?
`C##OPS_RO` aplica el principio de mínimo privilegio: se utiliza una cuenta común de observación y solo lectura, en vez de usar una cuenta administrativa para consultas rutinarias. No debería poder cambiar parámetros, crear o borrar usuarios/objetos, ni modificar la base; sus privilegios están destinados a consultar la información autorizada para monitorización.

**Evidencia:** `evidencia/spool/*_05-instancia-y-base.spool.log`; scripts de creación y concesión de la cuenta de observabilidad en `scripts/lab4/02-cuenta-observabilidad.sql`.

### 22. ¿Qué dos vías de exposición de contraseñas corrige este laboratorio respecto al Lab 3?
Primero, las contraseñas literales que quedaron en V000 se invalidan mediante V003, convirtiendo los propietarios `ADMIN_*` en cuentas de solo esquema con `NO AUTHENTICATION`; borrarlas del archivo no las eliminaría del historial Git. Segundo, `08-aplicar-migraciones.sh` deja de pasar `sys/<contraseña>` en la línea de comandos y utiliza autenticación del sistema operativo con `/ as sysdba`, evitando que la contraseña aparezca en `ps` o en los eventos de Docker.

**Evidencia:** `database/migrations/V003__cuentas_esquema_sin_password.sql`; `scripts/deployment/env/08-aplicar-migraciones.sh`; salida de la comprobación de secretos de J.2.

---

## Preguntas tipo examen P1–P12

### P1. Copia tras SHUTDOWN IMMEDIATE (elige dos)
**Respuestas: A y D.** Un apagado `IMMEDIATE` cierra la base limpiamente y deja los archivos consistentes. La copia puede restaurarse y abrirse sin recuperación de redo, siempre que se hayan copiado correctamente todos los archivos necesarios.

### P2. Mover un datafile en Standard Edition con breve indisponibilidad
**Respuesta: B.** Poner el tablespace `OFFLINE`, copiar el archivo con el sistema operativo, actualizar la ruta con `ALTER TABLESPACE ... RENAME DATAFILE` y volver a ponerlo `ONLINE`. `RENAME DATAFILE` por sí solo no copia el archivo.

### P3. V$INSTANCE y V$DATABASE (elige dos)
**Respuestas: A y C.** `STARTUP_TIME` cambia cada vez que arranca la instancia; `CREATED` indica cuándo se creó la base de datos. El DBID identifica la base y no cambia por recrear solo el contenedor.

### P4. Instancia en NOMOUNT (elige dos)
**Respuestas: A y C.** En `NOMOUNT` se puede consultar `V$PARAMETER` porque los parámetros ya se cargaron, y se puede crear/recrear el control file con `CREATE CONTROLFILE`. Aún no se han abierto los control files ni los datafiles.

### P5. ¿En qué etapa se ejecuta ALTER DATABASE ARCHIVELOG?
**Respuesta: B — MOUNT.** La base debe estar montada, con los control files abiertos, pero no abierta para uso normal.

### P6. `ALTER SYSTEM SET open_cursors = 500;` con SPFILE
**Respuesta: B.** Si no se especifica `SCOPE` y la instancia arrancó con SPFILE, el alcance por defecto es `BOTH`: el cambio se aplica en memoria y queda guardado en el SPFILE.

### P7. Cambiar PROCESSES desde FREEPDB1
**Respuesta: C.** Falla con ORA-65040 porque `PROCESSES` es un parámetro de instancia y no se modifica desde una PDB.

### P8. Recuperar una instancia que no arranca por un valor erróneo en SPFILE (elige dos)
**Respuestas: A y C.** Arrancar con un PFILE bueno mediante `STARTUP PFILE='/ruta/init_bueno.ora'` y recrear el SPFILE con `CREATE SPFILE FROM PFILE='/ruta/init_bueno.ora'`.

### P9. MEMORY_TARGET=0, SGA_TARGET=2G y DB_CACHE_SIZE=512M
**Respuesta: B.** ASMM administra la SGA y `DB_CACHE_SIZE` actúa como tamaño mínimo para el buffer cache; no significa que la caché tenga exactamente ese tamaño.

### P10. Dos estructuras de la PGA de un proceso servidor dedicado
**Respuestas: A y D.** El área de ordenación y la memoria de sesión del servidor dedicado pertenecen a la PGA. Shared pool, log buffer y buffer cache son estructuras de la SGA.

### P11. ¿Qué proceso debe escribir antes de que COMMIT devuelva el control?
**Respuesta: C — LGWR.** LGWR escribe los registros de redo necesarios para hacer durable el commit; DBWn escribe los bloques modificados en los datafiles posteriormente.

### P12. Dos procesos de background obligatorios
**Respuestas: B y D — PMON y SMON.** Ambos son procesos esenciales de la instancia. ARCn depende de ARCHIVELOG; CJQ0 y RECO no son obligatorios en todas las instancias.

---

## Revisión final antes del commit

- Reemplazar los campos entre corchetes en la respuesta 3 y el SPID de la respuesta 19 con valores reales.
- Confirmar que la ronda de caché citada en la respuesta 17 coincide con el log guardado.
- Confirmar que las evidencias referenciadas existen.
- No incluir `config/.env`, `backups/`, archivos `.tar.gz` ni contraseñas reales en Git.
- La PDF pide responder las 22 preguntas de comprobación y P1–P12 en `docs/bitacora/lab4-respuestas.md`.
