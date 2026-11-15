# Sistema de Monitoreo Sintético y Autorrecuperación Automatizada (T-60)

**Responsable:** Luis Vásquez Guido

Este repositorio contiene la implementación de los flujos de automatización desarrollados en **n8n** y el agente sintético (RPA) construido con **Robot Framework**, diseñados para monitorear, notificar y recuperar automáticamente los servicios críticos del proyecto (CRMs y Bases de Datos).

## Descripción General

El sistema se compone de tres pilares fundamentales:
*   **Monitoreo (Zabbix):** Detecta caídas de servicios o altos consumos de recursos (CPU, RAM).
*   **Orquestación (n8n):** Recibe las alertas de Zabbix, toma decisiones basadas en reglas de negocio y ejecuta acciones de remediación (reinicios vía SSH o API).
*   **Validación (Robot Framework):** Un agente sintético que simula el comportamiento de un usuario real (login, registro, consulta, búsqueda) para medir la experiencia de usuario y garantizar que el servicio esté 100% operativo tras una recuperación.

---

## Estructura del Repositorio

### Carpeta `/n8n`
Contiene los archivos `.json` de los flujos de trabajo exportados.

| Archivo | Descripción |
| :--- | :--- |
| `Alertas de Recursos Zabbix - Telegram.json` | Flujo de notificación general (12 categorías). |
| `CRM-Linux-Remediacion-T47.json` | Remediación automática para el CRM en Ubuntu. |
| `CRM-Windows-Remediacion-T47.json` | Remediación automática para el CRM en Windows. |
| `Autorrecuperacion-BD-MariaDB-Ubuntu.json` | Recuperación de la base de datos MariaDB en Linux. |
| `Autorrecuperacion-MariaDB-Windows.json` | Recuperación de la base de datos MariaDB en Windows. |
| `Reinicio-VM-por-alto-consumo.json` | Flujo de reinicio de VMs en Proxmox por saturación de recursos. |

### Carpeta `/robot`
Contiene los scripts del agente sintético.

| Archivo | Descripción |
| :--- | :--- |
| `crm_synthetic.robot` | Script principal de Robot Framework que ejecuta las pruebas en ambos CRMs. |
| `ejecutar_rpa.sh` | Script de Bash que orquesta la ejecución del robot y genera el JSON de salida. |

---

##  Funcionalidades Principales

### 1. Notificación y Clasificación de Alertas
Todos los eventos de Zabbix son recibidos por n8n y clasificados en 12 categorías (caídas, CPU alta, RAM alta, queries lentos, etc.). Se envía un mensaje formateado a Telegram con la severidad, el host y la hora exacta del evento.

### 2. Autorrecuperación de Servicios (CRM y BD)
*   **CRM Linux:** Si el contenedor Docker de EspoCRM se cae, n8n ejecuta un `docker restart`, verifica el HTTP y lanza el RPA.
*   **CRM Windows:** Si IIS se cae, n8n ejecuta un `Restart-Service W3SVC`, verifica el HTTP y lanza el RPA.
*   **Bases de Datos:** Si MariaDB (Ubuntu o Windows) se cae, n8n reinicia el servicio, verifica el puerto 3306 y notifica la recuperación.

### 3. Reinicio de VMs por Alto Consumo (Proxmox)
Si Zabbix detecta que el CPU o la RAM de una VM superan el umbral durante 5 minutos, n8n utiliza la API de Proxmox para reiniciar la máquina virtual. El flujo incluye un "cooldown" de 30 minutos y un máximo de 4 intentos para evitar bucles infinitos.

### 4. Agente Sintético (RPA) con Umbrales de Severidad
El script `crm_synthetic.robot` realiza las siguientes acciones:
*   **Generación de datos:** Crea contactos con nombres, correos y teléfonos únicos.
*   **Búsqueda por correo:** Verifica que el registro se haya guardado correctamente.
*   **Capturas de pantalla:** Toma evidencias visuales en cada paso (login, registro, consulta, búsqueda), independientemente de si el paso falló o no.
*   **Clasificación de tiempos:** n8n evalúa los tiempos de cada paso y los clasifica en 🟢 **Normal**, 🟠 **Advertencia** o 🔴 **Crítico**, enviando una alerta si el rendimiento se degrada.

---

## ⚙️ Requisitos de Instalación

Para replicar este entorno, se necesita:
*   **Zabbix Server** (con agentes en las VMs y SNMP para red).
*   **n8n** (con credenciales SSH configuradas para las VMs y tokens de API para Telegram y Proxmox).
*   **Robot Framework** (con las librerías `Browser`, `DateTime`, `OperatingSystem` y `Collections`).
*   **Google Chrome / Chromium** (para el navegador headless del RPA).

---

## Resultados y Evidencias

*   **Telegram:** Notificaciones en tiempo real de alertas, recuperaciones y degradaciones de rendimiento.
*   **Reportes HTML:** Robot Framework genera reportes detallados con capturas de pantalla de cada paso ejecutado.
*   **Historial CSV:** Los tiempos de cada ejecución se guardan en `/var/log/rpa/rpa_resultados.csv` para su posterior análisis en Grafana.
*   **Versionado de Código en GitHub**: Se realizó la actualización y el respectivo versionado de todos los componentes del sistema en el repositorio oficial del proyecto en GitHub. Todos los archivos fueron subidos sin credenciales reales.
