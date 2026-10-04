# T-10 · Automatización de remediación y RPA

Archivos técnicos de la tarea T-10 (Proyecto Integrador II, ITI-625, G-03). La documentación, las capturas y las pruebas están en Confluence (ficha T-10).

**Estado:** borrador de diseño. La implementación y validación en las VMs corresponde a T-24, T-28 y T-35.

## Estructura

```
T-10/
├── README.md
├── .gitignore
├── n8n/
│   ├── crm-remediacion.n8n.json
│   ├── ejemplo-evento-zabbix.json
│   └── sudoers-n8n-remed.example
└── robot/
    ├── .env.example
    ├── crm_synthetic.robot
    ├── logrotate-rpa.example
    └── systemd/
        ├── robot-crm.service
        └── robot-crm.timer
```

## Contenido

| Ruta | Descripción |
|---|---|
| `n8n/crm-remediacion.n8n.json` | Workflow de n8n (VM-07). Valida objetivo y tipo de incidente, aplica el límite de reinicios, reinicia el contenedor `espocrm-ubuntu` (VM-01) o el servicio IIS `W3SVC` (VM-02), verifica por HTTP y avisa por Telegram. |
| `n8n/ejemplo-evento-zabbix.json` | Ejemplo del cuerpo que Zabbix envía al webhook. |
| `n8n/sudoers-n8n-remed.example` | Regla `sudoers` de ejemplo en VM-01: limita al usuario de n8n a reiniciar solo ese contenedor. |
| `robot/crm_synthetic.robot` | Pruebas sintéticas de Robot Framework (VM-08): login, consulta y registro en CRM A (VM-01) y CRM B (VM-02). |
| `robot/.env.example` | Plantilla de las variables `CRM_USER` y `CRM_PASS` que usa el script. Se copia a `/etc/rpa/crm.env` en VM-08 (fuera del repositorio) y se completa allí; ver la sección «Configuración de credenciales del RPA». |
| `robot/systemd/robot-crm.service` y `.timer` | Ejecución programada del script cada 5 minutos; el servicio lee `/etc/rpa/crm.env`. |
| `robot/logrotate-rpa.example` | Rotación mensual del historial CSV, conservando 12 copias. |

## Configuración de credenciales del RPA (VM-08)

El script lee `CRM_USER` y `CRM_PASS` desde `/etc/rpa/crm.env`, un archivo que **no** está en el repositorio. Para crearlo a partir de la plantilla, ejecutar en VM-08 **desde la carpeta `T-10` del repositorio clonado** (la ruta `robot/.env.example` es relativa a esa carpeta, no a la raíz del repositorio):

```bash
cd T-10

# 1. Crear el usuario del servicio (solo si todavía no existe)
sudo useradd --system --create-home --home-dir /opt/rpa --shell /usr/sbin/nologin rpa

# 2. Crear el directorio y copiar la plantilla con permisos restringidos
sudo mkdir -p /etc/rpa
sudo install -m 600 -o rpa -g rpa robot/.env.example /etc/rpa/crm.env

# 3. Completar los valores reales (el archivo real nunca se sube a GitHub)
sudo nano /etc/rpa/crm.env
```

El servicio `robot-crm.service` carga ese archivo con `EnvironmentFile=/etc/rpa/crm.env`. El usuario `rpa` debe existir antes del paso 2, porque `install -o rpa -g rpa` falla si no existe.

## Validación del tipo de incidente (n8n)

El webhook de Zabbix debe enviar `target` e `incident_type`. Antes de reiniciar algo, el workflow comprueba que el tipo de incidente esté permitido para ese objetivo:

| Objetivo | Tipos permitidos |
|---|---|
| `crm_linux` (contenedor `espocrm-ubuntu`, VM-01) | `http_down`, `container_down` |
| `crm_windows` (servicio `W3SVC`, VM-02) | `http_down`, `service_down` |

Cualquier otro caso (por ejemplo CPU, RAM o disco altos, caída de MariaDB, o un `incident_type` ausente) **no reinicia nada**: se envía un aviso con el motivo y queda para intervención humana.

## Límite de reinicios (n8n)

Por objetivo se permiten como máximo **2 reinicios en 15 minutos**. Al superarlo, el workflow no reinicia y avisa que se alcanzó el límite, indicando en cuántos minutos se puede volver a intentar. Los valores se cambian en el nodo `Control de reinicios` (`MAX` y `VENTANA_MIN`).

El contador usa los datos estáticos del workflow, que **solo persisten con el workflow activo** (ejecuciones de producción), no en pruebas manuales.

## Historial del CSV (Robot Framework)

- Cada ejecución **agrega** filas a `rpa_resultados.csv`; el script nunca lo sobrescribe. El encabezado se crea solo si el archivo no existe o está vacío.
- El CSV está en una ruta fija y persistente (`/var/log/rpa/rpa_resultados.csv`, variable `HISTORIAL_CSV`), fuera de la carpeta de salida de Robot.
- Los `output.xml`, `log.html` y `report.html` se guardan con marca de tiempo (`--timestampoutputs`) y se limpian después de 14 días. El CSV no se borra.
- `robot/logrotate-rpa.example` rota el CSV cada mes y conserva 12 copias, para que el historial no crezca sin límite.

## Notas

- El nombre del contenedor (`espocrm-ubuntu`) corresponde al `compose.yaml` de T-09. Si cambia, actualizar el workflow y la regla `sudoers`.
- Los puertos y URLs de los CRM son los previstos; ajustar según el Compose e IIS desplegados.
- Los selectores de EspoCRM del script se deben verificar con la versión instalada.
- **No se versionan secretos:** tokens de n8n, claves SSH, usuario y clave del CRM. Van en las credenciales de n8n y en `/etc/rpa/crm.env`.
