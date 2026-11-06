# T-53 | Reejecución de flujos n8n y RPA A/B

**Responsable:** Luis Vásquez Guido
**Semana:** S9  

## Objetivo
Validar la reejecución de los flujos de remediación automática en n8n y las pruebas sintéticas de Robot Framework para ambos CRM, documentar los tiempos de respuesta obtenidos y verificar el versionado técnico en GitHub sin credenciales expuestas.

## Prueba A: CRM Linux (Ubuntu)
**Servidor:** VM-01-CRM-UBUN (192.168.20.11) / VM-07-n8n (192.168.50.11)
**Fecha y hora de recuperación:** 06/11/2026 a las 09:24:13 (CR)

**Procedimiento:**
1. Simulación de fallo deteniendo el contenedor (`sudo docker stop espocrm-ubuntu`).
2. Recepción del evento en n8n vía Webhook desde Zabbix.
3. Ejecución del flujo de remediación (Validación, límite de reinicios, SSH y reinicio).
4. Verificación HTTP (30s) y ejecución del RPA.

**Resultados reales:**
* **T-Acción:** 1.9 s
* **T-Recuperación:** 30.1 s
* **T-RPA:** 8.0 s (PASS) -> Login: 2.61s | Consulta: 1.28s | Registro: 0.53s
* **T-Total:** 41.6 s
* **Estado:** Recuperado correctamente | HTTP 200

## Prueba B: CRM Windows
**Servidor:** VM-02-CRM-WIN (192.168.20.12) / VM-07-n8n (192.168.50.11)
**Fecha y hora de recuperación:** 06/11/2026 a las 09:05:34 (CR)

**Procedimiento:**
1. Simulación de fallo deteniendo el servicio IIS (`Stop-Service W3SVC`).
2. Recepción del evento en n8n vía Webhook desde Zabbix.
3. Ejecución del flujo de remediación (Validación, SSH y reinicio).
4. Verificación HTTP y ejecución del RPA.

**Resultados reales:**
* **T-Acción:** 2.7 s
* **T-Recuperación:** 38.1 s
* **T-RPA:** 19.4 s (PASS) -> Login: 11.4s | Consulta: 2.79s | Registro: 0.99s
* **T-Total:** 61.7 s
* **Estado:** Recuperado correctamente | HTTP 200

## Verificación de aplicaciones
Se comprobó la disponibilidad de ambos EspoCRM tras las intervenciones automáticas. Las bases de datos de producción (MariaDB VM-03 y VM-04) no fueron modificadas ni intervinieron en el proceso de reinicio.

## Versionado de configuraciones
Se verificaron los archivos técnicos en el repositorio:
- Script de orquestación de RPA (`ejecutar_rpa.sh`)
- Workflows de n8n exportados en formato JSON (Linux y Windows)
- Scripts de Robot Framework (`guion_rpa_ubuntu.robot` y `guion_rpa_windows.robot`)

*Nota:* Se verificó que los archivos `.json`, `.sh` y `.robot` no contengan contraseñas en texto plano. Las credenciales se gestionan mediante variables de entorno.

## Evidencias
Las capturas de las ejecuciones (nodos en verde en n8n), los mensajes de Telegram (caída y recuperación) y los reportes de Robot Framework (PASS) se documentan detalladamente en la página de Confluence del proyecto.

## Conclusión
Se completaron las reejecuciones de prueba A/B para los flujos de n8n y RPA, validando la recuperación automática de ambos entornos con tiempos dentro de los límites aceptables (menores a 65 segundos). Se verificó el versionado técnico de los scripts y flujos en GitHub, garantizando la trazabilidad y seguridad del código sin exponer credenciales.
