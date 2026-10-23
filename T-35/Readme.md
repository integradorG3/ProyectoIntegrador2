# T-35 · Flujo n8n completo: remediación Linux/IIS, alertas y RPA con tiempo y resultado

Proyecto Integrador II (ITI-625), grupo G-03. Responsable: Luis Vásquez.
Sin secretos en este repositorio: tokens, claves y llaves se configuran en n8n, en `/etc/rpa/crm.env` o en el tipo de medio de Zabbix.

## Estructura
T-35/
├── n8n/
│ ├── crm-remediacion.n8n.json Workflow completo (importar en n8n, VM-07)
│ └── ejemplo-evento-zabbix.json Cuerpo de prueba para el webhook
├── zabbix/
│ ├── webhook-n8n.js Script del tipo de medio Webhook
│ └── mensajes-accion.md Mensaje JSON de cada acción y tabla de combinaciones
├── linux/
│ └── sudoers-n8n-remed.example VM-01: único comando permitido a n8n
├── robot/
│ ├── crm_synthetic.robot VM-08: Robot Framework modificado (credenciales A/B y sintaxis corregida)
│ ├── ejecutar_rpa.sh VM-08: corre el RPA y devuelve JSON con tiempo y resultado
│ └── sudoers-n8n-rpa.example VM-08: n8n solo puede ejecutar ese script
└── windows/
├── 01-openssh-n8n-remed.ps1 VM-02: OpenSSH, firewall solo desde n8n, cuenta limitada
├── 02-permiso-w3svc.ps1 VM-02: permiso solo sobre el servicio W3SVC
└── 03-validar-iis.ps1 VM-02: prueba controlada de caída/recuperación de IIS

text

## Requisitos Previos
*   **VM-08 (RPA):** Se requiere el robot `crm_synthetic.robot` (incluido en esta carpeta) copiado en `/opt/rpa/`. Este robot fue modificado para leer credenciales separadas (`CRM_USER_A/B`) y usar la librería `Browser` con Playwright.
*   **Dependencias RPA:** El usuario `rpa-runner` debe tener instalado `robotframework-browser` y los navegadores de Playwright (`rfbrowser init`).
*   **Red:** Zabbix (192.168.40.11, VLAN 40) debe alcanzar n8n (192.168.50.11:5678) y n8n (VLAN 50) debe alcanzar SSH/22 de VM-01 y VM-02 (VLAN 20).

## Cómo funciona el flujo

1. Zabbix detecta el problema y llama al webhook de n8n con `target`, `incident_type`, `event_id` y `event_time`.
2. **Validación:** solo se actúa si la combinación objetivo/tipo está permitida (Linux: `http_down`, `container_down`; Windows: `http_down`, `service_down`). Cualquier otra cosa solo genera aviso.
3. **Windows habilitado:** En esta implementación, `WINDOWS_HABILITADO = true` (se validó la remediación de IIS).
4. **Límite:** máximo 2 reinicios por objetivo en 15 minutos; al superarlo avisa y no reinicia.
5. **Acción:** Linux → `sudo /usr/bin/docker restart espocrm-ubuntu` (VM-01). Windows → `cmd /c "net stop W3SVC && net start W3SVC"` (VM-02).
6. Espera 30 s y consulta el HTTP del CRM.
7. **Si responde:** ejecuta el RPA del ambiente en VM-08 (login, consulta, registro) y avisa con tiempos y resultado de cada paso.
8. **Si no responde:** avisa FALLO (Telegram) y no ejecuta el RPA.

## Puesta en marcha

### 1. VM-01 (Linux)
```bash
sudo adduser --disabled-password --gecos "" n8n-remed
sudo install -d -m 700 -o n8n-remed -g n8n-remed /home/n8n-remed/.ssh
echo "<LLAVE_PUBLICA_DE_N8N>" | sudo tee -a /home/n8n-remed/.ssh/authorized_keys
sudo chown n8n-remed:n8n-remed /home/n8n-remed/.ssh/authorized_keys && sudo chmod 600 /home/n8n-remed/.ssh/authorized_keys
sudo cp linux/sudoers-n8n-remed.example /etc/sudoers.d/n8n-remed && sudo chmod 440 /etc/sudoers.d/n8n-remed
sudo visudo -c
2. VM-08 (RPA)
bash
sudo install -m 755 -o root -g root robot/ejecutar_rpa.sh /opt/rpa/ejecutar_rpa.sh
sudo adduser --disabled-password --gecos "" n8n-rpa
# Copiar la llave pública de n8n a /home/n8n-rpa/.ssh/authorized_keys
sudo cp robot/sudoers-n8n-rpa.example /etc/sudoers.d/n8n-rpa && sudo chmod 440 /etc/sudoers.d/n8n-rpa && sudo visudo -c

# Configurar credenciales en /etc/rpa/crm.env:
# CRM_USER_A=rpaubuntu
# CRM_PASS_A=****
# CRM_USER_B=rpawindows
# CRM_PASS_B=****
# PLAYWRIGHT_BROWSERS_PATH=/home/rpa-runner/.local/lib/...

# Prueba local (debe imprimir un JSON con PASS):
sudo -u rpa-runner /opt/rpa/ejecutar_rpa.sh A NO
3. VM-07 (n8n)
Importar n8n/crm-remediacion.n8n.json.

Crear credenciales: Header Auth (nombre X-Token), SSH Private Key para VM-01, VM-02 y VM-08, y Telegram.

Ajustar en cada nodo marcado REEMPLAZAR la credencial elegida y el chatId.

Verificar que WINDOWS_HABILITADO = true en el nodo Validar objetivo e incidente.

Probar con el webhook y luego publicar (Publish) el workflow. URL de producción: http://192.168.50.11:5678/webhook/crm-incidente.

4. VM-02 (Windows)
Para habilitar la remediación de IIS, ejecutar en PowerShell (como Administrador):

powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
New-LocalUser -Name "n8n-remed" -PasswordNeverExpires
Add-LocalGroupMember -Group "Administradores" -Member "n8n-remed"

# Permisos sobre el servicio W3SVC (ejecutar el script provisto):
.\02-permiso-w3svc.ps1
5. Zabbix (VM-05)
Crear el tipo de medio con zabbix/webhook-n8n.js (parámetros url, token, message) y las acciones de zabbix/mensajes-accion.md.

Estado de pruebas (Validado)
Probado en entorno real (VMs activas):

Linux (VM-01): El flujo recibió la alerta, reinició el contenedor Docker, verificó el HTTP (200), ejecutó el RPA y notificó a Telegram con tiempos y resultado PASS.

Windows (VM-02): El flujo recibió la alerta, se conectó por SSH y reinició el servicio IIS. El RPA se ejecutó exitosamente en el CRM Windows (PASS).

RPA: El robot crm_synthetic.robot fue modificado para leer variables de entorno (CRM_USER_A/B) y funciona correctamente para ambos entornos.

Notificaciones: Los mensajes de Telegram incluyen los tiempos exactos de acción, recuperación y el desglose del RPA.
