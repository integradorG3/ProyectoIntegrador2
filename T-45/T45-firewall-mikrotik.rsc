# =====================================================================
# Proyecto Integrador II - Grupo 3
# REAL T-45 (PI2-460) - Restriccion de acceso administrativo desde VLAN 60
# Simulacion de caida/alto trafico y validacion de segmentacion
# Responsable: Manuel Angel Chavarria Carbonero
# Aplicado: 30/10/2026 (RouterOS 6.46.8, MikroTik RB3011)
# Este archivo NO contiene contrasenas, claves ni tokens.
# =====================================================================
#
# Simulacion de caida controlada (ejecutada, ~6 min):
#   /interface disable vlan60-usuarios
#   /interface enable vlan60-usuarios
# Zabbix (SNMP) registro "MikroTik: Interface vlan60-usuarios(): Link down"
# de 19:24:44 a 19:30:44 y lo marco como resuelto.
#
# Hallazgo de la linea base: desde VLAN 60 eran accesibles SSH/Winbox del
# router (chain input) y los servicios de las VLAN 40 y 50.

/ip firewall filter
# Bloquea puertos de administracion del router desde usuarios
# (FTP, SSH, Telnet, WWW, WWW-SSL, Winbox, API, API-SSL).
# DHCP, DNS e ICMP hacia el router no se ven afectados.
add chain=input action=drop src-address=192.168.60.0/24 protocol=tcp dst-port=21,22,23,80,443,8291,8728,8729 comment="T45-BLOQUEAR-USUARIOS-ADMIN-ROUTER"

# Excepcion: VM-Cliente (192.168.60.20) puede consultar la web de Zabbix
add chain=forward action=accept src-address=192.168.60.20 dst-address=192.168.40.11 protocol=tcp dst-port=80 comment="T45-EXCEPCION-VMCLIENTE-ZABBIX-WEB"

# Usuarios sin acceso a servicios (VLAN 40) ni automatizacion (VLAN 50)
add chain=forward action=drop src-address=192.168.60.0/24 dst-address=192.168.40.0/24 comment="T45-BLOQUEAR-USUARIOS-A-SERVICIOS"
add chain=forward action=drop src-address=192.168.60.0/24 dst-address=192.168.50.0/24 comment="T45-BLOQUEAR-USUARIOS-A-AUTOMATIZACION"

# Nota: la excepcion debe quedar ANTES de T45-BLOQUEAR-USUARIOS-A-SERVICIOS.
# Si se agrega despues, usar:
#   place-before=[find comment="T45-BLOQUEAR-USUARIOS-A-SERVICIOS"]

# Verificacion:
#   /ip firewall filter print stats where comment~"T45"
#
# Reversion:
#   /ip firewall filter remove [find comment~"T45"]
