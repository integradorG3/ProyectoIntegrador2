
# T-47 · RPA exitoso/fallido de ambos CRM y evaluación de n8n

Pruebas reales del flujo Zabbix → n8n → reinicio → verificación HTTP → RPA → Telegram, en los dos CRM (A: Ubuntu/Docker, B: Windows/IIS), con un caso exitoso y un caso fallido en cada uno.

## Contenido

* n8n/ flujos de n8n (Linux y Windows), con credenciales sin incluir.
* robot/crm\_synthetic.robot robot RPA (timeout de navegación de 60 s).

## Resultados

|#|Hora (CR)|CRM|Servicio|Flujo|HTTP|T-acción|T-recuperación|T-total|RPA|
|-|-|-|-|-|-|-|-|-|-|
|P1|08:24:01|B Windows|W3SVC|RECUPERADO|200|1.5 s|38.5 s|60.1 s|PASS en 18.4 s (login 10.87 · consulta 2.43 · registro 1.0)|
|P2|08:31:01|A Ubuntu|espocrm-ubuntu|RECUPERADO|200|1.9 s|30.1 s|41.3 s|PASS en 7.8 s (login 3.12 · consulta 0.55 · registro 0.55)|
|P3|08:52:31|A Ubuntu|espocrm-ubuntu|FALLO|sin respuesta|0 s|n/d|30.1 s|no ejecutado|
|P4|09:00:01|B Windows|W3SVC|FALLO|sin respuesta|0.1 s|n/d|60.1 s|no ejecutado|

Notas:

* **Cómo se provocaron los fallos en P3 y P4:** se desactivó en n8n el nodo de reinicio (`Reiniciar contenedor (VM-01)` / `Reiniciar IIS (VM-02)`) y se detuvo el servicio a mano (`docker stop espocrm-ubuntu` / `Stop-Service W3SVC`). n8n no pudo recuperarlo, el HTTP no respondió y el flujo avisó por Telegram («Se requiere intervención humana») sin lanzar el RPA. Después se restauró el servicio a mano y se reactivó el nodo.
* En P3 y P4 el aviso dice «Reinicio: ejecutado» y T-acción ≈ 0 s porque el nodo desactivado deja pasar los datos; **no hubo reinicio real**.
* Metas de T-10 (T-acción ≤ 10 s, T-recuperación ≤ 120 s, T-total ≤ 3 min): cumplidas en los casos recuperados.

## Seguridad

Este directorio no contiene contraseñas, tokens ni `crm.env`. Las capturas están en Confluence.

