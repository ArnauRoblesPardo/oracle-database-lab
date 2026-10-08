# Lab 3 — Respuestas de comprobación

## 1. Docker

**1. ¿Qué diferencia hay entre una imagen y un contenedor?**

Una imagen es una plantilla para crear un entorno. Un contenedor es una instancia de esa imagen que se ejecuta o permanece detenida.

**2. En el Ejercicio G5 el archivo nota.txt desapareció y en el G6 no. Explica por qué.**

En G5, el archivo estaba dentro del contenedor y se perdió al eliminarlo. En G6, se utilizó almacenamiento persistente, por lo que el archivo se conservó.

**3. ¿Qué diferencia hay entre docker ps y docker ps -a, y qué significa STATUS = Exited (0)?**

`docker ps` muestra los contenedores en ejecución, mientras que `docker ps -a` muestra también los detenidos. `Exited (0)` significa que el proceso terminó correctamente.

**4. En -p 8181:8181, ¿qué número corresponde a tu equipo y cuál al contenedor? ¿Qué pasaría con -p 80:8080 en el ejercicio de nginx?**

En `-p 8181:8181`, el primer número es el puerto del equipo y el segundo el del contenedor. Con `-p 80:8080`, el puerto 80 del equipo se conectaría al 8080 del contenedor. Si Nginx escucha en el puerto 80 del contenedor, la configuración no funcionaría correctamente.

**5. ¿Por qué un contenedor de Oracle se queda en marcha y el de hello-world termina solo?**

Oracle debe permanecer activo para aceptar conexiones y gestionar la base de datos. `hello-world` ejecuta un mensaje y termina su proceso.

**6. ¿Qué es el digest de una imagen y por qué lo registramos si ya sabemos que usamos :latest?**

El digest identifica el contenido exacto de una imagen. Lo registramos porque la etiqueta `latest` puede apuntar a versiones diferentes con el tiempo.

**7. ¿Qué comando borraría realmente los datos de Oracle? ¿Por qué docker rm oralab-26ai no lo hace?**

Eliminar el volumen con `docker volume rm oralab-26ai-data` borraría los datos almacenados en él. `docker rm oralab-26ai` elimina el contenedor, pero no elimina automáticamente el volumen persistente.

---

## 2. Git, organización y evidencia

**8. ¿Por qué este laboratorio se hace dentro del repositorio oracle-database-lab, con Issue, branch y Pull Request, en vez de en una carpeta aparte?**

Porque permite versionar los cambios, relacionarlos con una tarea y revisarlos antes de integrarlos. Las ramas facilitan trabajar sin modificar directamente `main`.

**9. ¿Qué diferencia hay entre source 00-config.sh y bash 00-config.sh? ¿Por qué usamos source?**

`source` ejecuta el archivo en la shell actual y mantiene disponibles las variables definidas. `bash` lo ejecuta en un proceso separado. Utilizamos `source` para cargar la configuración en la terminal actual.

**10. Explica cada parte del nombre 20260915T091230Z_02-docker.script.log.**

`20260915` indica la fecha, `T` separa la fecha de la hora, `091230` indica la hora y `Z` señala que se utiliza UTC. `02-docker` identifica el paso y `.script.log` indica que es un registro de ejecución.

**11. ¿Para qué sirve .gitattributes y qué error evita?**

`.gitattributes` establece reglas para tratar los archivos dentro de Git, incluidos sus finales de línea. Ayuda a evitar problemas de compatibilidad entre Windows y Linux al ejecutar scripts.

**12. ¿Por qué en este Pull Request elegimos Create a merge commit en lugar de Squash and merge?**

Porque queremos conservar los commits individuales de la rama. El merge commit integra los cambios manteniendo ese historial.

---

## 3. Seguridad

**13. Describe las cuatro capas de la estrategia de contraseñas (Parte D) y qué pasaría si te saltas la primera.**

La contraseña real se guarda en `config/.env`, este archivo se excluye de Git mediante `.gitignore`, se utiliza `.env.example` como plantilla sin secretos y los scripts leen las contraseñas desde la configuración. Si se omite la protección inicial, una contraseña real podría acabar en el repositorio.

**14. ¿Por qué no escribimos la contraseña directamente en el comando docker run, aunque el script no se suba a Git?**

Porque podría quedar expuesta en el historial de la terminal, en la lista de procesos o en otros registros. Es más seguro obtenerla de una variable de configuración.

**15. Si descubres tu contraseña en un commit ya publicado, ¿basta con borrarla en un commit nuevo? ¿Qué debes hacer?**

No, porque la contraseña podría seguir apareciendo en el historial. Debemos cambiarla o revocarla, avisar al responsable y limpiar el historial publicado si corresponde.

---

## 4. Oracle y herramientas

**16. ¿Por qué no usamos SPOOL ni @archivo.sql con sqlplus dentro del contenedor, y qué hicimos en su lugar?**

Porque los archivos creados dentro del contenedor pueden no quedar guardados en el repositorio del equipo. Utilizamos herramientas como `tee` para registrar la salida desde el anfitrión y SQLcl desde el equipo cuando corresponde.

**17. ¿Qué hace WHENEVER SQLERROR EXIT SQL.SQLCODE al inicio de V000 y V001, y qué pasaría sin esa línea?**

Hace que la ejecución termine con un código de error si ocurre un error SQL. Sin esa instrucción, el script podría continuar y dejar una migración incompleta.

**18. ¿Qué es una migración y por qué V000 y V001 no se deben editar una vez aplicadas?**

Una migración es un archivo versionado que introduce cambios en la base de datos. No debe editarse después de aplicarse porque el archivo dejaría de coincidir con los cambios realizados. Las modificaciones posteriores deben hacerse mediante una nueva migración.

**19. ¿Por qué en SQL Developer se usa el servicio FREEPDB1 y no FREE ni un SID?**

Porque `FREEPDB1` es el servicio de la base de datos conectable en el que trabajamos. `FREE` identifica otro servicio y un SID utiliza un método de identificación diferente.

**20. ¿Qué aporta SQLcl frente a SQL*Plus, y por qué un DBA debe dominar ambas?**

SQLcl ofrece funciones modernas para trabajar con Oracle desde la línea de comandos. SQL*Plus es una herramienta tradicional muy utilizada. Conocer ambas permite trabajar con distintos entornos y scripts de administración.

---

## 5. Entorno de trabajo

**21. ¿Por qué el curso pasa de Git Bash a Ubuntu en WSL 2? Da al menos dos problemas concretos de Git Bash que desaparecen en Ubuntu.**

Ubuntu en WSL 2 ofrece un entorno Linux más parecido al de producción. Facilita la compatibilidad con comandos y herramientas de Linux y evita algunos problemas relacionados con las rutas y los permisos de Windows.

**22. ¿Por qué clonamos el repositorio en ~/oracle-database-lab y no trabajamos sobre la carpeta de Windows (/mnt/c/...)? ¿Y por qué recomendamos bash frente a zsh para los scripts del curso?**

Trabajar en `~/oracle-database-lab` utiliza el sistema de archivos Linux de WSL 2, lo que mejora el rendimiento y reduce algunos problemas de permisos y compatibilidad. Recomendamos Bash porque es el intérprete previsto para los scripts del curso y permite ejecutarlos de forma consistente.
