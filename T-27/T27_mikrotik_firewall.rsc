# REAL T-27 - Restricciones CRM/BD y publicación web
# Proyecto Integrador - Grupo 03
# No contiene credenciales ni secretos.

# Permitir que VM-01 use únicamente VM-03 como base de datos MariaDB.
/ip firewall filter add chain=forward action=accept protocol=tcp src-address=192.168.20.11 dst-address=192.168.30.11 dst-port=3306 comment="T27-PERMITIR-VM01-VM03-MARIADB" place-before=[find comment="defconf: fasttrack"]

# Bloquear a VM-01 el acceso TCP/3306 hacia otras bases de datos de VLAN 30.
/ip firewall filter add chain=forward action=drop protocol=tcp src-address=192.168.20.11 dst-address=192.168.30.0/24 dst-port=3306 comment="T27-BLOQUEAR-VM01-OTRAS-BD" place-before=[find comment="defconf: fasttrack"]

# Permitir a VLAN 60 acceso web a CRM-01 por TCP/8080.
/ip firewall filter add chain=forward action=accept protocol=tcp src-address=192.168.60.0/24 dst-address=192.168.20.11 dst-port=8080 comment="T27-PERMITIR-USUARIOS-CRM01-WEB" place-before=[find comment="defconf: fasttrack"]

# Permitir a VLAN 60 acceso web a CRM-02 por TCP/80.
/ip firewall filter add chain=forward action=accept protocol=tcp src-address=192.168.60.0/24 dst-address=192.168.20.12 dst-port=80 comment="T27-PERMITIR-USUARIOS-CRM02-WEB" place-before=[find comment="defconf: fasttrack"]

# Bloquear otros accesos desde VLAN 60 hacia VLAN 20.
/ip firewall filter add chain=forward action=drop src-address=192.168.60.0/24 dst-address=192.168.20.0/24 comment="T27-BLOQUEAR-USUARIOS-OTROS-ACCESOS-APPS" place-before=[find comment="defconf: fasttrack"]
