#Preguntas de comprobación

### 1. ¿Cuántos errores ORA- tenía tu alert log en 24 h en la Parte B y a qué se debían? ¿Por qué ese número no es una alarma por sí solo?

En la Parte B hemos visto que en las últimas 24 h se han registrado 2 errores ORA-.
Los errores registrados en la parte posterior son del tipo ORA-00800 (se trata de errores relacionados con que Oracle ha intentado dar mayor prioridad a los procesos VKTM y LGWR y no ha podido debido a las restricciones del sistema operativo). Además también tenemos errores ORA-65019 (intentando abrir una PDB que ya estaba abierta). Aunque estos son de una consulta posterior y no sé si realmente son los mismos 2 errores de antes.
Solo con el número de errores no podemos asegurar que haya algún problema grave. Es importante saber de qué tipo de error se trata, cuantas veces ocurre y si afecta al funcionamiento de la base de datos.

### 2. ¿A qué hora empieza y cuánto dura la ventana de mantenimiento de un miércoles en tu base? ¿Qué tareas automáticas corren en ella?

Esta ventana WEDNESDAY_WINDOW comienza a las 22:00 de los miércoles y tiene una duración de 4h (termina a las 02:00 del día siguiente).
En esta ventana se tienen activas 3 tareas automáticas: auto optimizer stats collection (estadísticas para el optimizador), auto space advisor (analiza el uso del espacio) y sql tuning advisor (analiza mejoras de consultas SQL).

### 3. Explica con tu salida de la Parte C la diferencia entre lo que mostraban V$SPPARAMETER y V$PARAMETER tras el SCOPE = SPFILE. ¿Qué habría pasado en el siguiente reinicio sin el RESET?

Inicialmente el valor de db_files era 200. Hemos modificado el valor (con SCOPE=SPFILE) a 250.
En V$SPPARAMETER aparece el valor 250 (es el que está almacenado en el SPFILE). En V$PARAMETER sigue apareciendo 200 (el que está en uso en la instancia).
El parámetro db_files es de tipo estático. No puede modificarse directamente en memoria. En el siguiente reinicio Oracle hubiese cargado el valor almacenado en el SPFILE (250) porque no hubiésemos hecho el RESET.

### 4. ¿Por qué RESET fue la vuelta atrás correcta para db_files y no lo habría sido para processes? Cita la línea de tu PFILE que lo demuestra.

Hemos utilizado RESET en el caso de db_files porque inicialmente no estaba explícitamente definido en el SPFILE (ISSPECIFIED=FALSE). Con esto hemos dejado que Oracle tome el valor por defecto.
En el caso de processes en nuestro PFILE tenemos un valor explícito:`31*:processes=200`
En este caso no hubiese sido correcto utilizar RESET (habríamos borrado el valor original). Habría sido más adecuado volver al valor de la copia de seguridad (200).

### 5. Tras el reinicio sin estado guardado, ¿qué error obtuvo C##OPS_RO y por qué la instancia decía «Database opened»?

Tras el reinicio (sin guardar el estado de la PDB) la PDB estaba en estado MOUNTED (FREEPDB1). Al intentar acceder a ella desde C##OPS_RO hemos obtenido el error ORA-01109: database not open.
Database opened hace referencia a que la base de datos (CDB) está abierta. En nuestro caso estábamos en una instancia abierta. Pero nuestra PDB (FREEPDB1) estaba en estado MOUNTED (no estaba disponible para la aplicación).

### 6. ¿Qué SID, SPID y evento tenía la sesión de la aplicación en tu ejecución? ¿Qué te dicen MODULE, ACTION y CLIENT_IDENTIFIER que no te diría USERNAME?

Los datos de la sesión de la aplicación son los siguientes:

SID: 58.
SERIAL#: 47893.
SPID: 5624.
Evento: PL/SQL lock timer.
USERNAME: APP_ACADEMIA.
SERVICE_NAME: academia_app.
MODULE: matriculas.
ACTION: cierre-periodo.
CLIENT_IDENTIFIER: ana.garcia@ucam.

Con el campo USERNAME solo sabríamos el usuario que está conectando. Con los campos MODULE, ACTION y CLIENT_IDENTIFIER conocemos mejor qué está haciendo la aplicación (en nuestro caso estamos en el módulo matriculas haciendo la acción cierre-periodo) y quién es el usuario que está haciendo la operación (en nuestro caso Ana García).

### 7. Tras CANCEL SQL, ¿cuántas transacciones abiertas tenía la aplicación? ¿Y tras KILL SESSION? ¿En qué estado quedó la fila 101 y por qué?

Tras el CANCEL SQL la aplicación tenía una transacción abierta (cancelar la sentencia que se estaba ejecutando no implica cerrar la sesión ni cancelar la transacción completa).
Posteriormente hemos realizado el KILL SESSION '58,47893' IMMEDIATE. La sesión ha terminado (hay 0 sesiones activas de la aplicación).
La fila 101 queda en estado ACTIVO. Se estaba haciendo un cambio que aún no se había confirmado. Al finalizar la sesión Oracle realiza un rollback (deshace la transacción pendiente) y devuelve el estado anterior de la fila.

### 8. ¿Qué valor tiene common_user_prefix en tu imagen? ¿Qué implica para el nombre de una cuenta común?

En nuestro caso el parámetro common_user_prefix está vacío. Esto quiere decir que no es necesario utilizar un prefijo determinado (como C##) para crear una cuenta común.
Por tanto podemos crear usuarios comunes sin necesidad de utilizar el prefijo.

### 9. Completa con tus cifras la tabla de las tres miradas (ALL_TABLES, DBA_USERS, CDB_USERS, V$DATAFILE) y explica una diferencia.

Las 3 consultas en las diferentes conexiones han arrojado los siguientes resultados:

Consulta C##OPS_RO en CDB$ROOT C##OPS_RO en FREEPDB1 APP_ACADEMIA en FREEPDB1

ALL_TABLES de ADMIN_ACADEMIA 0 0 1
DBA_USERS 37 47 ORA-00942
CDB_USERS CON_ID 1: 37 CON_ID 3: 47 ORA-00942
V$DATAFILE 17 10 ORA-00942

Información adicional: USER_TABLES en las 3 conexiones da 0. ALL_USERS en raíz da 37 y en PDB 47.
La principal diferencia es el nivel de permisos y el contenedor en el que estamos. Desde CDB$ROOT (con C##OPS_RO) tenemos configurado CONTAINER_DATA=ALL y podemos acceder a información de varios contenedores. Desde FREEPDB1 solo tenemos acceso a la información de esta PDB.
Por otro lado, el usuario APP_ACADEMIA tiene permisos para acceder a la tabla de ADMIN_ACADEMIA (que es la que tiene autorizado) pero no tiene permisos para acceder a vistas administrativas (DBA_USERS, CDB_USERS y V$DATAFILE). Por este motivo obtiene ORA-00942.

### 10. Con tu salida de 04-deltas: ¿cuántas lecturas lógicas por recorrido y cuánto DB time costó la carga? ¿Qué indica la relación entre DB time y DB CPU?

En nuestra prueba se han realizado 59.513 lecturas lógicas en 10 recorridos (media de 5.951 por recorrido).
El DB time de la carga es de 0,32 segundos. El DB CPU es de 0,31 segundos. Son prácticamente iguales. Esto quiere decir que hemos invertido casi todo el tiempo en trabajo de CPU (prácticamente no hemos tenido tiempos de espera).

### 11. Da las tres medidas (asignado, libre, máximo) de TBS_ACADEMIA_HIST antes de la carga y explica cuál usarías para alertar.

Antes de la carga tenemos los siguientes valores en TBS_ACADEMIA_HIST:

Espacio asignado: 10 MB.
Espacio libre: 3,9 MB.
Tamaño máximo: 40 MB.

Para alertar deberíamos tomar en cuenta el porcentaje de ocupación (respecto al máximo permitido) y el espacio libre. Es importante tener en cuenta que el tablespace puede crecer de manera automática. Por lo que el espacio asignado no es siempre el límite real.

### 12. ¿Quién insertó y quién «pagó» en el ORA-01950? ¿Por qué ampliar el tablespace no habría resuelto el ORA-01536?

En la primera prueba se ha realizado la inserción desde la sesión administrativa. El segmento es del usuario CARGA_HIST. Por lo que es necesario que este tenga cuota en TBS_ACADEMIA_HIST.
Como no tenía cuota asignada ha saltado el error ORA-01950. Posteriormente hemos asignado cuota (de 2MB) a este usuario. Volvimos a cargar y salta el error ORA-01536 (superamos la cuota asignada).
No hubiese sido solución aumentar el tamaño del tablespace. El problema no estaba en el espacio físico del tablespace sino en que el propietario del segmento no tenía cuota. La solución ha sido aumentar la cuota de CARGA_HIST a 30MB.

### 13. ¿Cuánto tiempo estuvo suspendida la carga reanudable y qué evidencia de ello dejó Oracle en el alert log?

Hemos configurado la carga como reanudable (con un máximo de 180 segundos de espera). Cuando hemos superado la cuota del TBS_ACADEMIA_HIST Oracle no ha cancelado directamente la operación. Ha dejado la operación en estado suspendido (por el error ORA-01536).
En el alert log se deja constancia de que se ha suspendido la sentencia (carga-historico) y posteriormente se reanuda. En concreto se ha suspendido a las 07:40:57.641 y se ha reanudado a las 07:41:08.559. Por tanto ha estado suspendido durante unos 10,92 segundos.
Una vez hemos aumentado la cuota del propietario (a 30MB) Oracle ha podido continuar la operación. Se han insertado correctamente las 20.000 filas.

### 14. Antes y después del SHRINK: filas, bloques y cuota consumida. ¿Por qué un DELETE no devolvió el espacio?

Antes de eliminar los datos teníamos 20.000 filas. Consumía unos 23MB de cuota. Tenía 2.944 bloques.
Tras eliminar 18.000 filas (queda 2.000 registros) sigue ocupando 2.944 bloques (consume unos 23MB). El DELETE no provoca que se libere espacio automáticamente.
Tras el SHRINK sigue con 2.000 filas. Ahora ocupa 304 bloques (consume unos 2,4 MB). De esta forma Oracle ha podido liberar el espacio que ya no necesita el segmento.

### 15. ¿Qué valores tenía tu perfil DEFAULT? Justifica dos de los límites de PRF_PERSONAS para una persona de secretaría.

Consultando el perfil DEFAULT de nuestra base de datos tenemos los siguientes valores:

Parámetro Valor

FAILED_LOGIN_ATTEMPTS 10
INACTIVE_ACCOUNT_TIME 365
PASSWORD_GRACE_TIME 7
PASSWORD_LIFE_TIME 180
PASSWORD_LOCK_TIME 1
PASSWORD_REUSE_MAX UNLIMITED
PASSWORD_REUSE_TIME UNLIMITED
PASSWORD_ROLLOVER_TIME 0
PASSWORD_VERIFY_FUNCTION NULL

Para la cuenta de una persona de secretaría hemos configurado el perfil PRF_PERSONAS. En él tenemos 3 intentos fallidos (con lo que reducimos el riesgo de que se intente acceder con muchas contraseñas distintas), un tiempo de bloqueo de 1 minuto (configuración específica de este laboratorio, que no es la que utilizaríamos en un entorno real), 90 días de vida de la contraseña (con lo que obligamos a que se renueven periódicamente) y 7 días de gracia. Además hemos indicado que se utilice la función ORA12C_VERIFY_FUNCTION para comprobar la complejidad de las contraseñas.

### 16. ¿Por qué Ana pudo leer ACA_MATRICULAS si nadie se la concedió por nombre? ¿Qué error obtuvo al cambiar el nombre de un alumno?

Ana tiene asignado el rol ROL_SECRETARIA_ACADEMIA. Este rol tiene asignado el rol ROL_LECTURA_ACADEMIA. En este último tenemos el privilegio SELECT ANY TABLE ON SCHEMA ADMIN_ACADEMIA. Con esto podemos acceder a cualquier tabla de este esquema.
Al intentar modificar el nombre de un alumno ha recibido el error ORA-41900: missing UPDATE privilege. Esto es debido a que solo tenemos permiso de actualización sobre la columna ESTADO. Por tanto podemos modificar el estado de los alumnos, pero no sus nombres.

### 17. ¿Qué objetos se invalidaron en cada uno de los tres cambios de columna y por qué no se invalidó nada con la columna nueva?

Inicialmente tenemos la función F_TOTAL_ACTIVOS_LAB6 y las vistas V_ACTIVOS_LAB6 y V_CONTACTO_LAB6 en estado VALID.
Al añadir una nueva columna (que no es utilizada por ningún objeto existente) no se invalida ningún objeto.
Al ampliar la columna email_institucional se invalida la vista V_CONTACTO_LAB6.
Al ampliar la columna nombres se invalidan la función y las dos vistas. Esto es debido a que dependen de la tabla y de las columnas que hemos modificado. Posteriormente hemos realizado las recompilaciones pertinentes. Al final no quedaban objetos de negocio inválidos.

### 18. Según tus advisors, ¿mejoraría el DB time duplicar la SGA? ¿Y por debajo de qué tamaño la PGA tendría sobreasignaciones?

De acuerdo con el asesor de SGA, no es conveniente aumentar la memoria (de 1.536 MB a 3.072 MB) ya que no mejora el DB time (factor de mejora es 1).
En el caso de la PGA tenemos 5 sobreasignaciones para 128 MB y 256 MB. Para 384 MB ya no tenemos sobreasignaciones. En nuestro caso el umbral es de 384 MB (en nuestro entorno de laboratorio).

### 19. ¿Cuántas lecturas lógicas necesitó la consulta de la aplicación según la traza (o tkprof)? ¿Qué línea de la traza lo dice?

La consulta de la aplicación ha necesitado 247 lecturas lógicas. En la salida de tkprof tenemos FETCH query=247 (disk=0).
En la traza tenemos la línea FETCH p=0, cr=247. En esta línea el parámetro cr corresponde a las lecturas lógicas y p a las lecturas físicas. Por tanto se han realizado 247 lecturas lógicas y ninguna física.

### 20. Para cada incidente de la guardia: evidencia clave, intervención y validación (una línea por cada uno).

- **INC-601 – Bloqueo al guardar la ficha de un alumno:** La sesión SID 56 de `APP_ACADEMIA`, con módulo `matriculas` y acción `cierre-periodo`, bloqueaba a la sesión SID 65 de `ANA_GARCIA` al acceder a la fila 101 de `ACA_ESTUDIANTES`; ejecuté `ALTER SYSTEM KILL SESSION '56,231' IMMEDIATE` para terminar la sesión bloqueadora y liberar el bloqueo, y comprobé la recuperación de la operación de la aplicación.

- **INC-602 – Servicio de aplicación no anunciado por el listener:** Comprobé que `FREEPDB1` estaba abierta, pero que `academia_app` no estaba activo ni anunciado por el listener; ejecuté el procedimiento de arranque del servicio mediante `DBMS_SERVICE.START_SERVICE` y guardé su estado para futuros reinicios. Después comprobé que el listener anunciaba `academia_app` y `freepdb1` en estado `READY`.

- **INC-603 – Cuenta de aplicación bloqueada:** Al investigar el error `ORA-28000`, comprobé que `APP_ACADEMIA` estaba en estado `LOCKED`, no `LOCKED(TIMED)`, y que utilizaba el perfil `DEFAULT`; cambié al contenedor `FREEPDB1` y ejecuté `ALTER USER APP_ACADEMIA ACCOUNT UNLOCK`. Al repetir el diagnóstico, la cuenta dejó de aparecer entre las cuentas bloqueadas.
