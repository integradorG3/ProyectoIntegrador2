# T-09 - EspoCRM Ubuntu con Docker Compose

## Descripción

Esta configuración corresponde a la instancia de EspoCRM sobre Ubuntu del Proyecto Integrador II.

La aplicación se ejecutará mediante Docker y Docker Compose en la máquina virtual VM-01-CRM-UBUN (ID 104).

La base de datos se mantiene en un servidor independiente, VM-03-Ubuntu-BD (ID 106), por lo que no se incluye un contenedor de base de datos dentro del archivo compose.yaml.

## Arquitectura

VM-01-CRM-UBUN (104)
- Ubuntu Server
- Docker / Docker Compose
- EspoCRM

        |
        | Conexión a base de datos
        v

VM-03-Ubuntu-BD (106)
- Ubuntu Server
- Servidor de base de datos

## Archivos

- compose.yaml: definición de los servicios Docker necesarios para EspoCRM.
- .env.example: plantilla de las variables de entorno necesarias para el despliegue.
- README.md: documentación de la configuración.

## Variables de entorno

Antes del despliegue se deberá crear un archivo `.env` basado en `.env.example`.

El archivo `.env` contendrá los valores reales correspondientes al entorno, incluyendo la dirección del servidor de base de datos y las credenciales necesarias.

El archivo `.env` real no debe almacenarse en el repositorio.

## Base de datos independiente

La configuración utiliza una base de datos externa.

El parámetro DB_HOST deberá apuntar a la dirección IP definitiva de VM-03-Ubuntu-BD.

El puerto previsto para la conexión MySQL/MariaDB es 3306.

## Seguridad

No se almacenan contraseñas, tokens ni otras credenciales reales en los archivos versionados.

Las credenciales reales deberán mantenerse únicamente en el entorno donde se realice el despliegue.

## Versión de EspoCRM

La configuración de Docker Compose utiliza la imagen `espocrm/espocrm:10.0.9`.

Se utiliza una versión específica de la imagen en lugar de la etiqueta `latest` para mantener un despliegue controlado y reproducible, evitando cambios automáticos de versión.

## Red Docker

La configuración utiliza la red predeterminada creada automáticamente por Docker Compose.

Los servicios definidos en `compose.yaml` se conectan a esta red para su comunicación interna. No se define una red Docker personalizada debido a que la base de datos se encuentra en un servidor independiente, VM-03-Ubuntu-BD (ID 106), y no dentro del mismo entorno de contenedores.

La conexión entre EspoCRM y la base de datos externa se realizará mediante la red de la máquina virtual, utilizando la dirección del servidor definida en la variable `DB_HOST` del archivo `.env`.

Para esta comunicación, VM-01-CRM-UBUN deberá tener conectividad hacia VM-03-Ubuntu-BD por el puerto 3306 de MySQL/MariaDB.


