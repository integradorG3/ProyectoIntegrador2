# T-52 | Restauración de datos A/B y versionado

**Responsable:** Monserrat Moreno
**Semana:** S9
**Requerimiento:** REQ-02

## Objetivo
Validar la restauración de datos de prueba en MariaDB Linux y Windows,
y documentar las configuraciones versionadas sin secretos.

## Prueba A: MariaDB Linux
Servidor: VM-03-BD-UBUN (192.168.30.11)

Base de origen: prueba_restauracion_t44
Base restaurada: prueba_restauracion_t52_linux
Respaldo: /var/backups/prueba_restauracion_t52_linux.sql

Procedimiento:
1. Generar respaldo con mariadb-dump.
2. Crear una base de datos de prueba independiente.
3. Importar el respaldo con mariadb.
4. Consultar la tabla verificacion.

Resultado: 3 registros restaurados correctamente.

## Prueba B: MariaDB Windows
Servidor: VM-04-BD-WIN (192.168.30.12)

Base de origen: prueba_restauracion_t44
Base restaurada: prueba_restauracion_t52_windows
Respaldo: C:\Respaldos_T52\prueba_restauracion_t52_windows.sql

Procedimiento:
1. Generar respaldo con mariadb-dump.exe.
2. Crear una base de datos de prueba independiente.
3. Importar el respaldo con mariadb.exe.
4. Consultar la tabla verificacion.

Resultado: 3 registros restaurados correctamente.

## Verificación de aplicaciones
Se comprobó el funcionamiento de EspoCRM Linux y Windows.
Las bases de datos de producción no fueron modificadas.

## Versionado de configuraciones
Se verificaron los archivos de T-09/ubuntu-docker:
- compose.yaml
- .env.example
- .gitignore
- README.md

El archivo .env está excluido de Git.
Las contraseñas identificadas en Compose utilizan variables de entorno.

## Evidencias
Las capturas de respaldos, restauraciones y validaciones
se documentan en Confluence.

## Conclusión
Se completaron las restauraciones de prueba A/B y se verificó
el versionado existente de Docker Compose.
