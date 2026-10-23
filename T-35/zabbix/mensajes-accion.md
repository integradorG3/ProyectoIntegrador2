# Mensaje de las acciones de Zabbix (cuerpo JSON)

En Zabbix: Alertas > Acciones > Acciones de trigger > Crear accion.
En la pestana **Operaciones**, enviar mensaje al usuario/medio **n8n** (tipo Webhook de `webhook-n8n.js`)
y pegar el siguiente texto en **Mensaje** (el asunto puede quedar vacio o con cualquier texto).
Todo el mensaje debe ser JSON valido, sin saltos de linea extra ni texto fuera de las llaves.

## Una accion por cada combinacion (condicion: nombre del trigger o etiqueta)

| Accion (nombre sugerido) | Condicion | `target` | `incident_type` |
|--------------------------|-----------|----------|-----------------|
| CRM Linux - HTTP caido | Trigger = `CRM Ubuntu: HTTP no responde` | `crm_linux` | `http_down` |
| CRM Linux - Contenedor caido | Trigger = `CRM Ubuntu: contenedor espocrm-ubuntu detenido` | `crm_linux` | `container_down` |
| CRM Windows - HTTP caido | Trigger = `CRM Windows: HTTP no responde` | `crm_windows` | `http_down` |
| CRM Windows - IIS detenido | Trigger = `CRM Windows: servicio W3SVC detenido` | `crm_windows` | `service_down` |

Los nombres de trigger son ejemplos: usar los reales de Zabbix (los crea Estefania / quien administre VM-05).

## Plantilla del mensaje (cambiar solo target e incident_type)

```
{"target":"crm_linux","incident_type":"container_down","event_id":"{EVENT.ID}","event_time":"{EVENT.DATE} {EVENT.TIME}"}
```

`{EVENT.DATE}` llega como `2026.10.15` y `{EVENT.TIME}` como `14:05:30`, en la zona horaria del servidor Zabbix
(por eso el nodo *Validar objetivo e incidente* tiene `TZ_ZABBIX = '-06:00'`).

## Recuperacion (opcional)

Para esta tarea NO se envia nada cuando el problema se resuelve: el flujo solo se dispara con el problema.
En la accion, dejar vacia la pestana **Operaciones de recuperacion**. Evita que n8n reciba eventos que no debe procesar.
