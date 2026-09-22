**¿Cuál es la diferencia entre Working Directory, Staging Area y Local Repository? Da un ejemplo de un archivo pasando por las tres.**


El Working Directory es la carpeta del proyecto donde están los archivos que estoy modificando. La Staging Area es una zona intermedia donde selecciono los cambios que quiero incluir en el siguiente commit. El Local Repository es el historial de commits que Git guarda dentro de la carpeta .git.

Por ejemplo, si modifico README.md, primero el cambio está en el Working Directory. Cuando hago git add README.md, pasa a la Staging Area. Finalmente, cuando hago git commit, ese cambio queda guardado en el historial del repositorio local.



**Si modificas un archivo pero no haces git add, ¿aparece ese cambio en tu próximo commit? Explica por qué.**



No. Si modifico un archivo pero no hago git add, el cambio se queda en el Working Directory y no pasa a la Staging Area.

El commit solamente incluye los cambios que están preparados en la Staging Area. Por eso primero hay que hacer git add y después git commit.



**¿Por qué git status no mostraba las carpetas vacías que creaste en la Parte C? ¿Qué truco usamos para solucionarlo?**



Porque Git no controla las carpetas directamente, sino los archivos. Si una carpeta está completamente vacía, Git no tiene ningún archivo que pueda registrar.

Para solucionarlo usamos un archivo vacío llamado .gitkeep dentro de las carpetas. De esta forma Git tiene un archivo que puede controlar y la estructura de carpetas queda guardada en el repositorio.



**Explica con tus palabras qué es HEAD.**



HEAD es un puntero que indica dónde estoy actualmente dentro del historial de Git. Normalmente apunta a la branch en la que estoy trabajando y, a través de ella, al commit actual.

Por ejemplo, si estoy en master, HEAD indica que mi posición actual está en esa branch. Cuando cambio de branch, HEAD cambia para indicar la nueva branch.



**¿Qué diferencia hay entre crear una branch con git switch -c y crear una carpeta nueva con mkdir? ¿Cómo lo comprobamos en la Parte G?**



git switch -c crea una nueva línea de trabajo dentro del historial de Git. No crea una carpeta física nueva.

En cambio, mkdir solamente crea una carpeta en el disco y no crea ninguna branch ni modifica el historial de Git.

En la Parte G lo comprobamos creando una branch y viendo que el contenido seguía estando en la misma carpeta del proyecto. También usamos el historial de Git para comprobar las diferentes ramas.



**Durante el conflicto de la Parte H, ¿qué representaba el contenido entre <<<<<<< HEAD y =======? ¿Y entre ======= y >>>>>>>?**



El contenido entre <<<<<<< HEAD y ======= representaba la versión que tenía actualmente en mi branch, es decir, la versión de HEAD.

El contenido entre ======= y >>>>>>> representaba la versión que venía de la otra branch que Git estaba intentando fusionar.

Git coloca estos marcadores porque no puede decidir automáticamente qué versión debe quedarse cuando las dos branches han modificado la misma parte del archivo.



**¿Por qué NO se debe hacer git commit --amend sobre un commit que ya se subió con git push?**



Porque git commit --amend modifica el último commit y reescribe el historial. Al hacerlo se genera otro commit con un hash diferente.

Si ese commit ya se ha subido a GitHub, otras personas pueden tener la versión anterior del historial y pueden aparecer problemas al sincronizar los repositorios.

Por eso --amend se puede utilizar para corregir un commit que todavía es solamente local, pero después de hacer push es mejor crear un nuevo commit.



**Si borras por accidente la carpeta .git de tu proyecto, ¿qué se pierde exactamente? ¿Se pierde también el código fuente que está en el disco?**



Se pierde el repositorio Git local, es decir, el historial de commits, las branches y la configuración que Git guarda dentro de .git.

El código fuente que está en la carpeta del proyecto no se borra, porque los archivos del proyecto están fuera de .git.

Por tanto, seguiría teniendo mis archivos, pero Git ya no tendría la información del historial de ese proyecto en esa carpeta.





**Explica con tus propias palabras la diferencia entre Git y GitHub, sin usar la palabra "nube".**



Git es la herramienta que utilizo en mi ordenador para controlar las versiones de un proyecto. Me permite hacer commits, crear branches, consultar el historial y trabajar con los cambios.

GitHub es un servicio donde puedo alojar una copia remota del repositorio Git y sincronizarla con mi repositorio local mediante push y pull.



**¿Por qué no se debe subir un archivo .env con contraseñas reales a un repositorio, aunque el repositorio sea privado?**



Porque el archivo .env puede contener información sensible como contraseñas, claves o tokens. Aunque el repositorio sea privado, esas credenciales podrían quedar expuestas a personas que tengan acceso al repositorio o podrían acabar filtrándose.

Además, una vez que un secreto entra en el historial de Git, eliminar el archivo posteriormente no significa necesariamente que haya desaparecido del historial.

Por eso es recomendable utilizar un .gitignore para evitar subir estos archivos y crear un .env.example sin las contraseñas reales.



**Un compañero te dice: "hice push y ahora GitHub me rechaza el segundo push con non-fast-forward". ¿Qué ha ocurrido probablemente y qué comando ejecutarías primero?**



Probablemente el repositorio remoto tiene commits que todavía no están en el repositorio local. Por ejemplo, alguien pudo hacer un cambio directamente en GitHub.

Antes de volver a hacer push, ejecutaría:

git pull

Esto trae los cambios del repositorio remoto y los fusiona con mi copia local. Después, si todo está correcto, podría volver a hacer git push.



**¿Qué tipo de Conventional Commit (feat, fix, docs, test…) usarías para: añadir un índice de rendimiento a una tabla, corregir una restricción mal definida, y actualizar el README?**



Para añadir un índice de rendimiento a una tabla usaría perf, porque es una mejora relacionada con el rendimiento.

Para corregir una restricción mal definida usaría fix, porque estamos corrigiendo un error.

Para actualizar el README usaría docs, porque es un cambio relacionado con la documentación.

Por ejemplo:

perf: add index to customer table

&#x20;fix: correct customer constraint

&#x20;docs: update README













