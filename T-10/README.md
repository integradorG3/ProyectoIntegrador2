# T-10 · Automatización de remediación y RPA

Archivos técnicos de la tarea T-10 (Proyecto Integrador II, ITI-625, G-03). La documentación, las capturas y las pruebas están en Confluence.

**Estado:** borrador de diseño. La implementación y validación en las VMs corresponde a T-24, T-28 y T-35.

## Contenido

| Ruta | Descripción |
|---|---|
| `n8n/crm-remediacion.n8n.json` | Workflow de n8n (VM-07). Recibe el webhook de Zabbix, valida que el objetivo esté autorizado, reinicia el contenedor `espocrm-ubuntu` (VM-01) o el servicio IIS `W3SVC` (VM-02), espera 30 s, verifica por HTTP y avisa por Telegram. |
| `n8n/sudoers-n8n-remed.example` | Ejemplo de regla `sudoers` en VM-01 que limita al usuario de n8n a reiniciar solo ese contenedor. |
| `robot/crm_synthetic.robot` | Pruebas sintéticas de Robot Framework (VM-08): login, consulta y registro en CRM A (VM-01) y CRM B (VM-02). Registra resultado y duración por paso en `rpa_resultados.csv`. |
| `robot/systemd/robot-crm.service` y `.timer` | Ejemplo de ejecución programada del script cada 5 minutos. |
| `.env.example` | Variables de entorno que usa el script (sin valores reales). |

## Notas

- El nombre del contenedor (`espocrm-ubuntu`) corresponde al `compose.yaml` de T-09. Si cambia, actualizar el workflow y la regla `sudoers`.
- Los puertos y URLs de los CRM son los previstos; ajustar según el Compose e IIS desplegados.
- Los selectores de EspoCRM del script se deben verificar con la versión instalada.
- **No se versionan secretos:** tokens de n8n, claves SSH, usuario y clave del CRM. Van en las credenciales de n8n y en variables de entorno.
