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

Para el despliegue se requiere:

- IIS habilitado en Windows Server.
- PHP compatible con la versión de EspoCRM utilizada.
- IIS URL Rewrite.
- Extensiones de PHP requeridas por EspoCRM.
- Conectividad entre VM-02-CRM-WIN y VM-04-Windows-BD.
- Acceso al puerto correspondiente del servicio de base de datos.

## Base de datos independiente

La instancia de EspoCRM instalada en VM-02-CRM-WIN utilizará la base de datos alojada en VM-04-Windows-BD.

La dirección IP definitiva, nombre de la base de datos, usuario y contraseña deberán configurarse durante el despliegue.

Las credenciales reales no deben almacenarse en este repositorio.

## web.config

El archivo web.config contiene configuración de IIS para la aplicación web.

Incluye la definición de index.php como documento predeterminado y reglas de reescritura necesarias para dirigir las solicitudes hacia la aplicación.

La configuración deberá ser validada en VM-02-CRM-WIN antes de utilizarse en producción.

## Seguridad

No se almacenan contraseñas, tokens ni otras credenciales reales dentro de los archivos versionados.

La comunicación con la base de datos deberá limitarse a los equipos y puertos requeridos por la aplicación.