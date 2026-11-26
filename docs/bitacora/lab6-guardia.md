## INC-601 · Bloqueo al guardar la ficha de un alumno

- **Detección:** 15:33 UTC · Ana García, de secretaría, avisó de que la pantalla se quedaba bloqueada al guardar la ficha del alumno 101. Indicó que ya había reiniciado su ordenador dos veces.
- **Impacto:** Ana no podía guardar los datos del alumno 101. La duración de la incidencia no quedó registrada.
- **Diagnóstico:** La sesión de `ANA_GARCIA`, SID 65, estaba esperando por un bloqueo `enq: TX - row lock contention`. La sesión bloqueadora era `APP_ACADEMIA`, SID 56 y SERIAL# 231, ejecutando el módulo `matriculas` y la acción `cierre-periodo`. El objeto afectado era `ACA_ESTUDIANTES`, fila 101. La transacción tenía `used_ublk = 1` y `used_urec = 1`.
- **Causa raíz:** La aplicación mantenía una transacción sin confirmar que bloqueaba la fila del alumno 101 e impedía que secretaría pudiera completar el guardado.
- **Intervención:** Se ejecutó `ALTER SYSTEM KILL SESSION '56,231' IMMEDIATE;` para terminar únicamente la sesión bloqueadora, sin reiniciar la instancia. Fue la intervención más pequeña posible porque afectaba solo a la sesión responsable del bloqueo. La transacción tenía un bloque y un registro pendientes de deshacer.
- **Validación:** Oracle respondió `System altered.` al ejecutar la sentencia. La comprobación definitiva de que la ficha 101 quedó en estado `ACTIVO` se realizará con la verificación final de la Parte J.
- **Acción preventiva:** Supervisar las transacciones abiertas y los bloqueos prolongados, especialmente durante el cierre de período, y revisar que la aplicación confirme sus transacciones correctamente.

## INC-602 · Servicio de aplicación no anunciado por el listener

- **Detección:** 15:33 UTC · El equipo de matrículas avisó de que la aplicación no podía conectar y mostraba el error ORA-12514.
- **Impacto:** El equipo de matrículas no podía utilizar la aplicación. La duración exacta de la incidencia no quedó registrada.
- **Diagnóstico:** La base de datos `FREEPDB1` estaba arrancada (`SI`), pero el servicio `academia_app` no estaba activo (`NO`). Al consultar el listener, únicamente aparecía `freepdb1`, sin anunciarse `academia_app`.
- **Causa raíz:** El servicio `academia_app` existía, pero no estaba arrancado y, por tanto, el listener no podía ofrecerlo a los clientes.
- **Intervención:** Se ejecutó el script `scripts/lab6/03-servicio.sql` mediante `bash scripts/ops/sysdba.sh scripts/lab6/03-servicio.sql "$EVID_LAB6/script/$(ts)_03-servicio.script.log"`. El script arrancó el servicio y guardó su estado para futuros reinicios. Se utilizó el procedimiento existente para recuperar el servicio sin reiniciar la base de datos.
- **Validación:** Se volvió a consultar el estado del listener y aparecieron tanto `academia_app` como `freepdb1` en estado `READY`.
- **Acción preventiva:** Asegurar que el servicio de aplicación se arranque automáticamente después de los reinicios mediante `SAVE STATE` y supervisar periódicamente los servicios anunciados por el listener.

## INC-603 · Cuenta de aplicación bloqueada

- **Detección:** 15:33 UTC · El equipo de matrículas avisó de que la aplicación no permitía iniciar sesión y mostraba ORA-28000. Indicó que no se había cambiado la contraseña. En el turno de tarde también se informó de que ese día se había ejecutado el script trimestral de bajas.
- **Impacto:** La aplicación no podía autenticarse utilizando la cuenta `APP_ACADEMIA`. La duración exacta de la incidencia no quedó registrada.
- **Diagnóstico:** La cuenta `APP_ACADEMIA` aparecía con estado `LOCKED` y perfil `DEFAULT`, cuyo límite era de 10 intentos fallidos. No aparecía como `LOCKED(TIMED)`, por lo que el bloqueo apuntaba a una intervención manual o de un script y no al bloqueo automático por intentos fallidos.
- **Causa raíz:** El script trimestral de bajas habría bloqueado también una cuenta de aplicación. El problema está en que el procedimiento de bajas no distingue adecuadamente entre cuentas de personas y cuentas técnicas utilizadas por las aplicaciones.
- **Intervención:** Primero se cambió al contenedor `FREEPDB1` mediante `ALTER SESSION SET CONTAINER = FREEPDB1;` y después se ejecutó `ALTER USER APP_ACADEMIA ACCOUNT UNLOCK;`. Se desbloqueó únicamente la cuenta afectada, sin cambiar su contraseña ni modificar su perfil.
- **Validación:** Se volvió a ejecutar `08-diagnostico.sql` y `APP_ACADEMIA` dejó de aparecer entre las cuentas bloqueadas.
- **Acción preventiva:** Modificar el script trimestral de bajas para excluir las cuentas técnicas y de aplicación, diferenciándolas de las cuentas personales antes de aplicar bloqueos.
