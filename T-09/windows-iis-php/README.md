# T-09 - EspoCRM Windows con IIS/PHP

## Descripción

Esta configuración corresponde a la instancia de EspoCRM sobre Windows Server del Proyecto Integrador II.

La aplicación se desplegará en la máquina virtual VM-02-CRM-WIN (ID 103), utilizando IIS como servidor web y PHP para la ejecución de EspoCRM.

La base de datos se mantendrá en un servidor independiente, VM-04-Windows-BD (ID 105).

## Arquitectura

VM-02-CRM-WIN (103)
- Windows Server
- IIS
- PHP
- EspoCRM

        |
        | Conexión a base de datos
        v

VM-04-Windows-BD (105)
- Windows Server
- Servidor de base de datos

## Componentes requeridos

Para el despliegue de EspoCRM en VM-02-CRM-WIN se requiere:

### IIS

- Internet Information Services (IIS) habilitado en Windows Server.
- IIS URL Rewrite instalado.
- PHP integrado con IIS mediante FastCGI.
- Configuración de `index.php` como documento predeterminado.
- Reglas de reescritura configuradas mediante el archivo `web.config`.
- El sitio de IIS deberá apuntar al directorio `public` de EspoCRM.
- Se deberá configurar el directorio `client` como directorio virtual según la configuración recomendada para EspoCRM.

### PHP

EspoCRM requiere PHP 8.3 a 8.5.

Extensiones PHP requeridas:

- pdo_mysql
- gd con soporte FreeType
- openssl
- zip
- mbstring
- iconv
- curl
- xml
- xmlwriter
- exif
- bcmath

Valores mínimos recomendados en `php.ini`:

- `max_execution_time = 180`
- `max_input_time = 180`
- `memory_limit = 256M`
- `post_max_size = 50M`
- `upload_max_filesize = 50M`

### Base de datos

La base de datos no se instalará en VM-02-CRM-WIN.

EspoCRM se conectará al servidor independiente VM-04-Windows-BD (ID 105), por lo que deberá existir conectividad entre ambas máquinas virtuales y acceso al puerto correspondiente del servicio MySQL/MariaDB.

## web.config

El archivo web.config contiene configuración de IIS para la aplicación web.

Incluye la definición de index.php como documento predeterminado y reglas de reescritura necesarias para dirigir las solicitudes hacia la aplicación.

La configuración deberá ser validada en VM-02-CRM-WIN antes de utilizarse en producción.

## Seguridad

No se almacenan contraseñas, tokens ni otras credenciales reales dentro de los archivos versionados.

La comunicación con la base de datos deberá limitarse a los equipos y puertos requeridos por la aplicación.
