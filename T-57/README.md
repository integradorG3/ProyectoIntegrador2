# T-57 — Demostración de red: VLAN, NAT/PAT, acceso a CRM y bloqueo administrativo desde Usuarios (G3)

Responsable: Manuel Ángel Chavarría Carbonero · 13/11/2026 · Jira PI2-475

Configuración final presentada en la demostración. Es la misma versionada en T-51; durante la T-57 no se realizaron cambios.

| Archivo | Contenido |
|---|---|
| `T57-mikrotik.rsc` | `/export hide-sensitive` del MikroTik RB3011 (RouterOS 6.46.8): VLAN, DHCP, firewall T22/T27/T41/T45, NAT masquerade. Número de serie omitido. |
| `T57-cisco.txt` | `show running-config` del Cisco SW-G3-PRINCIPAL: VLAN, trunks Gi0/1–Gi0/2, puertos de acceso. Hash del usuario reemplazado por `<OMITIDO>`. |
| `T57-diagrama-red-G3.drawio` / `.png` | Diagrama final de red. |

## Pruebas desde VM-Cliente (192.168.60.20, VLAN 60 Usuarios)

| Destino | Esperado | Resultado |
|---|---|---|
| CRM-01 192.168.20.11:8080 | Permitido | True |
| CRM-02 192.168.20.12:80 | Permitido | True |
| SSH VM-01 192.168.20.11:22 | Bloqueado | False |
| RDP VM-02 192.168.20.12:3389 | Bloqueado | False |
| MariaDB VM-03 192.168.30.11:3306 | Bloqueado | False |
| SSH router 192.168.60.1:22 | Bloqueado | False |
| Winbox router 192.168.60.1:8291 | Bloqueado | False |
| n8n VM-07 192.168.50.11:5678 | Bloqueado | False |

Ningún archivo contiene contraseñas, claves SNMP ni tokens.
