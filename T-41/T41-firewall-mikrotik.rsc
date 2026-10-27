# =====================================================================
# Proyecto Integrador II - Grupo 3
# REAL T-41 (PI2-450) - Reglas de firewall MikroTik RB3011
# Conectividad VM-05 Zabbix / VM-06 Grafana / VM-07 n8n / VM-08 RPA
# con ambos CRM (VLAN 20) y sus bases de datos (VLAN 30)
# Responsable: Manuel Angel Chavarria Carbonero
# Aplicado: 26/10/2026 (RouterOS, cadena forward, al final de la cadena)
# Este archivo NO contiene contrasenas, claves ni tokens.
# =====================================================================
#
# Respaldo previo ejecutado:
#   /system backup save name=antes-T41
#   /export file=antes-T41
#
# Nota: RouterOS no acepto varias direcciones separadas por coma en
# dst-address; por eso se usa una regla por direccion.

/ip firewall address-list
add list=T41-SERVICIOS address=192.168.40.0/24 comment="VLAN 40 Servicios (Zabbix, Grafana)"
add list=T41-SERVICIOS address=192.168.50.0/24 comment="VLAN 50 Automatizacion (n8n, RPA)"
add list=T41-APPS-BD address=192.168.20.0/24 comment="VLAN 20 Aplicaciones (CRM)"
add list=T41-APPS-BD address=192.168.30.0/24 comment="VLAN 30 Bases de datos"
add list=T41-AUTOMATIZACION address=192.168.50.11 comment="VM-07 n8n"
add list=T41-AUTOMATIZACION address=192.168.50.12 comment="VM-08 RPA"

/ip firewall filter
# --- Monitoreo Zabbix (VM-05 192.168.40.11) ---
add chain=forward action=accept src-address=192.168.40.11 dst-address-list=T41-APPS-BD protocol=tcp dst-port=10050 comment="T41-PERMITIR-ZABBIX-AGENTES"
add chain=forward action=accept src-address=192.168.40.11 dst-address-list=T41-APPS-BD protocol=icmp comment="T41-PERMITIR-ZABBIX-ICMP"
add chain=forward action=accept src-address=192.168.40.11 dst-address=192.168.20.11 protocol=tcp dst-port=8080 comment="T41-PERMITIR-ZABBIX-HTTP-CRM01"
add chain=forward action=accept src-address=192.168.40.11 dst-address=192.168.20.12 protocol=tcp dst-port=80 comment="T41-PERMITIR-ZABBIX-HTTP-CRM02"
add chain=forward action=accept src-address-list=T41-APPS-BD dst-address=192.168.40.11 protocol=tcp dst-port=10051 comment="T41-PERMITIR-AGENTES-ZABBIX"
# --- Automatizacion n8n / RPA -> web de ambos CRM ---
add chain=forward action=accept src-address-list=T41-AUTOMATIZACION dst-address=192.168.20.11 protocol=tcp dst-port=8080 comment="T41-PERMITIR-AUTO-CRM01-WEB"
add chain=forward action=accept src-address-list=T41-AUTOMATIZACION dst-address=192.168.20.12 protocol=tcp dst-port=80 comment="T41-PERMITIR-AUTO-CRM02-WEB"
# --- Monitoreo MariaDB ---
add chain=forward action=accept src-address=192.168.40.11 dst-address=192.168.30.11 protocol=tcp dst-port=3306 comment="T41-PERMITIR-ZABBIX-MARIADB-VM03"
add chain=forward action=accept src-address=192.168.40.11 dst-address=192.168.30.12 protocol=tcp dst-port=3306 comment="T41-PERMITIR-ZABBIX-MARIADB-VM04"
# --- Remediacion automatica n8n por SSH (T-35) ---
add chain=forward action=accept src-address=192.168.50.11 dst-address=192.168.20.11 protocol=tcp dst-port=22 comment="T41-PERMITIR-N8N-SSH-VM01"
add chain=forward action=accept src-address=192.168.50.11 dst-address=192.168.20.12 protocol=tcp dst-port=22 comment="T41-PERMITIR-N8N-SSH-VM02"
# --- Bloqueo final: resto de VLAN 40/50 hacia aplicaciones y BD ---
add chain=forward action=drop src-address-list=T41-SERVICIOS dst-address-list=T41-APPS-BD comment="T41-BLOQUEAR-SERVICIOS-A-APPS-BD"

# Verificacion:
#   /ip firewall address-list print where list~"T41"
#   /ip firewall filter print where comment~"T41"
#   /ip firewall filter print stats where comment~"T41"
#
# Reversion:
#   /ip firewall filter remove [find comment~"T41"]
#   /ip firewall address-list remove [find list~"T41"]
