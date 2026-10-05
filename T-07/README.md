# Configuración de Router MikroTik y Switch Cisco
## Proyecto Integrador II — Semana 2

> **Objetivo:** registrar los comandos utilizados o necesarios para reproducir la configuración de red realizada hasta este punto.
>
> **Importante para GitHub:** este archivo no contiene contraseñas ni credenciales reales. Los valores sensibles, como contraseñas y comunidad SNMP, se muestran como variables `<...>` y deben mantenerse fuera del repositorio.

---

# 1. Topología utilizada

```text
Red Universidad / Internet
          |
       ether2
          |
   MikroTik RB3011
          |
       ether3
        TRUNK
          |
        Gi0/1
   Cisco Catalyst 2960
          |
        Gi0/2
        TRUNK
          |
       Proxmox
```

Redes configuradas:

| VLAN | Nombre | Red | Gateway |
|---|---|---|---|
| 10 | Administración | 192.168.10.0/24 | 192.168.10.1 |
| 20 | Aplicaciones | 192.168.20.0/24 | 192.168.20.1 |
| 30 | Base de datos | 192.168.30.0/24 | 192.168.30.1 |
| 40 | Servicios | 192.168.40.0/24 | 192.168.40.1 |
| 50 | Automatización | 192.168.50.0/24 | 192.168.50.1 |
| 60 | Usuarios | 192.168.60.0/24 | 192.168.60.1 |

Direcciones relevantes:

```text
MikroTik VLAN 10       192.168.10.1
Cisco VLAN 10          192.168.10.2
AD DS / DNS            192.168.10.10
Zabbix                  192.168.40.11
Red legacy MikroTik     192.168.88.0/24
MikroTik legacy         192.168.88.1
```

---

# 2. MikroTik RB3011

## 2.1 WAN

La conexión WAN se utiliza sobre `ether2`.

Comandos de verificación:

```routeros
/ip dhcp-client print
/ip route print
/interface list member print
```

Debe existir una ruta por defecto `0.0.0.0/0` y `ether2` debe formar parte de la lista `WAN`.

Si fuera necesario agregar `ether2` a la lista WAN:

```routeros
/interface list member add list=WAN interface=ether2
```

> En el equipo ya existía una regla NAT/PAT tipo `masquerade`, por lo que no se debe crear una segunda regla duplicada.

Verificación:

```routeros
/ip firewall nat print
/ip firewall nat print stats
```

---

## 2.2 Retirar ether3 del bridge para utilizarlo como trunk VLAN

```routeros
/interface bridge port remove [find interface=ether3]
```

Verificación:

```routeros
/interface bridge port print
```

---

## 2.3 Creación de interfaces VLAN sobre ether3

```routeros
/interface vlan add name=vlan10-admin interface=ether3 vlan-id=10
/interface vlan add name=vlan20-app interface=ether3 vlan-id=20
/interface vlan add name=vlan30-db interface=ether3 vlan-id=30
/interface vlan add name=vlan40-servicios interface=ether3 vlan-id=40
/interface vlan add name=vlan50-auto interface=ether3 vlan-id=50
/interface vlan add name=vlan60-usuarios interface=ether3 vlan-id=60
```

Verificación:

```routeros
/interface vlan print
```

---

## 2.4 Gateways de las VLAN

```routeros
/ip address add address=192.168.10.1/24 interface=vlan10-admin
/ip address add address=192.168.20.1/24 interface=vlan20-app
/ip address add address=192.168.30.1/24 interface=vlan30-db
/ip address add address=192.168.40.1/24 interface=vlan40-servicios
/ip address add address=192.168.50.1/24 interface=vlan50-auto
/ip address add address=192.168.60.1/24 interface=vlan60-usuarios
```

Verificación:

```routeros
/ip address print
```

---

## 2.5 Agregar las VLAN a la lista LAN

```routeros
/interface list member add list=LAN interface=vlan10-admin
/interface list member add list=LAN interface=vlan20-app
/interface list member add list=LAN interface=vlan30-db
/interface list member add list=LAN interface=vlan40-servicios
/interface list member add list=LAN interface=vlan50-auto
/interface list member add list=LAN interface=vlan60-usuarios
```

Verificación:

```routeros
/interface list member print
```

---

## 2.6 DHCP

El diseño actual utiliza DHCP únicamente para:

- VLAN 10 — Administración.
- VLAN 60 — Usuarios.

Las VLAN 20, 30, 40 y 50 utilizan direccionamiento estático para los servidores.

### Pool VLAN 10

Si el pool todavía no existe:

```routeros
/ip pool add name=pool-vlan10 ranges=192.168.10.100-192.168.10.199
```

Si ya existe:

```routeros
/ip pool set [find name="pool-vlan10"] ranges=192.168.10.100-192.168.10.199
```

### Servidor DHCP VLAN 10

Si todavía no existe:

```routeros
/ip dhcp-server add name=dhcp-vlan10 interface=vlan10-admin address-pool=pool-vlan10 lease-time=1d disabled=no
```

Si ya existe:

```routeros
/ip dhcp-server set [find name="dhcp-vlan10"] interface=vlan10-admin address-pool=pool-vlan10 lease-time=1d disabled=no
```

### Pool VLAN 60

Si el pool todavía no existe:

```routeros
/ip pool add name=pool-vlan60 ranges=192.168.60.100-192.168.60.199
```

Si ya existe:

```routeros
/ip pool set [find name="pool-vlan60"] ranges=192.168.60.100-192.168.60.199
```

### Servidor DHCP VLAN 60

Si todavía no existe:

```routeros
/ip dhcp-server add name=dhcp-vlan60 interface=vlan60-usuarios address-pool=pool-vlan60 lease-time=1d disabled=no
```

Si ya existe:

```routeros
/ip dhcp-server set [find name="dhcp-vlan60"] interface=vlan60-usuarios address-pool=pool-vlan60 lease-time=1d disabled=no
```

### Redes DHCP

Mientras el servidor AD DS/DNS no esté operativo se puede utilizar temporalmente DNS público:

```routeros
/ip dhcp-server network set [find address="192.168.10.0/24"] gateway=192.168.10.1 dns-server=8.8.8.8
/ip dhcp-server network set [find address="192.168.60.0/24"] gateway=192.168.60.1 dns-server=8.8.8.8
```

Configuración definitiva una vez que el DNS de AD DS `192.168.10.10` esté operativo:

```routeros
/ip dhcp-server network set [find address="192.168.10.0/24"] gateway=192.168.10.1 dns-server=192.168.10.10
/ip dhcp-server network set [find address="192.168.60.0/24"] gateway=192.168.60.1 dns-server=192.168.10.10
```

Verificación:

```routeros
/ip pool print
/ip dhcp-server print
/ip dhcp-server network print
/ip dhcp-server lease print
```

> El DHCP original `defconf` de la red `192.168.88.0/24` se conserva como red de administración/recuperación.

---

## 2.7 Reglas de acceso entre VLAN

Bloquear Usuarios (VLAN 60) hacia Administración (VLAN 10):

```routeros
/ip firewall filter add chain=forward action=drop src-address=192.168.60.0/24 dst-address=192.168.10.0/24 comment="BLOQUEAR-USUARIOS-A-ADMIN" place-before=[find comment="defconf: fasttrack"]
```

Bloquear Usuarios (VLAN 60) hacia Base de Datos (VLAN 30):

```routeros
/ip firewall filter add chain=forward action=drop src-address=192.168.60.0/24 dst-address=192.168.30.0/24 comment="BLOQUEAR-USUARIOS-A-BD" place-before=[find comment="defconf: fasttrack"]
```

Cuando el servidor AD DS/DNS esté operativo, permitir exclusivamente DNS desde Usuarios hacia `192.168.10.10` **antes** de la regla de bloqueo general hacia VLAN 10:

```routeros
/ip firewall filter add chain=forward action=accept protocol=udp src-address=192.168.60.0/24 dst-address=192.168.10.10 dst-port=53 comment="PERMITIR-DNS-ADDS-USUARIOS-UDP" place-before=[find comment="BLOQUEAR-USUARIOS-A-ADMIN"]
/ip firewall filter add chain=forward action=accept protocol=tcp src-address=192.168.60.0/24 dst-address=192.168.10.10 dst-port=53 comment="PERMITIR-DNS-ADDS-USUARIOS-TCP" place-before=[find comment="BLOQUEAR-USUARIOS-A-ADMIN"]
```

Verificación:

```routeros
/ip firewall filter print
```

---

## 2.8 SSH y acceso administrativo al MikroTik

Habilitar SSH:

```routeros
/ip service enable ssh
/ip service set ssh port=22
```

Restringir SSH y WinBox a las redes administrativas:

```routeros
/ip service set ssh address=192.168.88.0/24,192.168.10.0/24
/ip service set winbox address=192.168.88.0/24,192.168.10.0/24
```

Verificación:

```routeros
/ip service print
```

### Contraseña / usuario

Nunca guardar la contraseña real en GitHub.

Ejemplo de cambio de contraseña:

```routeros
/user set [find name="admin"] password="<PASSWORD>"
```

Ejemplo recomendado de usuario administrativo independiente:

```routeros
/user add name=<ADMIN_USER> group=full password="<PASSWORD>"
```

---

## 2.9 SNMP para Zabbix

Servidor Zabbix:

```text
192.168.40.11
```

Se utiliza SNMPv2c en modo de solo lectura.

Habilitar SNMP:

```routeros
/snmp set enabled=yes
```

Crear comunidad restringida únicamente a Zabbix:

```routeros
/snmp community add name=<SNMP_COMMUNITY_RO> addresses=192.168.40.11/32 read-access=yes write-access=no
```

Verificación:

```routeros
/snmp print
/snmp community print detail
```

> `<SNMP_COMMUNITY_RO>` representa la comunidad real y no debe almacenarse en un repositorio público.

---

## 2.10 Exportación de respaldo

```routeros
/export hide-sensitive file=T07_MikroTik_G3
```

Ver archivos:

```routeros
/file print
```

El archivo generado aparece en WinBox → **Files** como:

```text
T07_MikroTik_G3.rsc
```

---

# 3. Cisco Catalyst 2960 Plus

## 3.1 Configuración básica

```cisco
enable
configure terminal
hostname SW-G3-PRINCIPAL
```

---

## 3.2 Creación de VLAN

```cisco
vlan 10
 name ADMINISTRACION
exit

vlan 20
 name APLICACIONES
exit

vlan 30
 name BASE_DATOS
exit

vlan 40
 name SERVICIOS
exit

vlan 50
 name AUTOMATIZACION
exit

vlan 60
 name USUARIOS
exit
```

Verificación:

```cisco
show vlan brief
```

---

## 3.3 Interfaz administrativa VLAN 10

```cisco
configure terminal
interface vlan 10
 ip address 192.168.10.2 255.255.255.0
 no shutdown
exit

ip default-gateway 192.168.10.1
end
```

Verificación:

```cisco
show ip interface brief
show running-config | include default-gateway
```

### Interfaz VLAN 1 temporal

Durante las pruebas se utilizó temporalmente:

```cisco
interface vlan 1
 ip address 192.168.88.2 255.255.255.0
 no shutdown
```

Una vez validada completamente la administración mediante VLAN 10, esta dirección temporal puede retirarse:

```cisco
configure terminal
interface vlan 1
 no ip address
exit
end
```

> No retirar `192.168.88.2` hasta confirmar que `192.168.10.2` es accesible y administrable.

---

## 3.4 Gi0/1 — Trunk hacia MikroTik

```cisco
configure terminal
interface GigabitEthernet0/1
 description TRUNK-HACIA-MIKROTIK
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30,40,50,60
 switchport nonegotiate
 no shutdown
exit
end
```

---

## 3.5 Gi0/2 — Trunk hacia Proxmox

```cisco
configure terminal
interface GigabitEthernet0/2
 description TRUNK-HACIA-PROXMOX
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30,40,50,60
 switchport nonegotiate
 no shutdown
exit
end
```

Verificación de ambos trunks:

```cisco
show interfaces trunk
show interfaces status
```

---

## 3.6 Puertos de acceso

Configuración actual:

- `Fa0/2`: Administración — VLAN 10.
- `Fa0/1`: Usuarios — VLAN 60.
- `Fa0/3` a `Fa0/24`: Usuarios — VLAN 60.

### Fa0/2 — Administración

```cisco
configure terminal
interface FastEthernet0/2
 description ADMINISTRACION
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast
 no shutdown
exit
```

### Fa0/1 — Usuarios

```cisco
interface FastEthernet0/1
 description USUARIOS
 switchport mode access
 switchport access vlan 60
 spanning-tree portfast
 no shutdown
exit
```

### Fa0/3 a Fa0/24 — Usuarios

```cisco
interface range FastEthernet0/3 - 24
 description USUARIOS
 switchport mode access
 switchport access vlan 60
 spanning-tree portfast
 no shutdown
exit
end
```

Verificación:

```cisco
show vlan brief
show interfaces status
```

> Durante las pruebas, `Fa0/4` se utilizó temporalmente como access VLAN 30 para validar el aislamiento entre Usuarios y Base de Datos. Posteriormente se devolvió a VLAN 60 como parte de la distribución final de puertos.

Configuración temporal utilizada en la prueba:

```cisco
configure terminal
interface FastEthernet0/4
 description PRUEBA-VLAN30-BD
 switchport mode access
 switchport access vlan 30
 spanning-tree portfast
 no shutdown
end
```

---

## 3.7 SSH en el Cisco

Configurar dominio:

```cisco
configure terminal
ip domain-name proyecto.local
```

Crear usuario local administrativo:

```cisco
username admin privilege 15 secret <PASSWORD>
```

Generar claves RSA:

```cisco
crypto key generate rsa modulus 2048
```

Habilitar SSH versión 2:

```cisco
ip ssh version 2
```

Configurar líneas VTY:

```cisco
line vty 0 15
 login local
 transport input ssh
 exec-timeout 15 0
exit
end
```

Verificación:

```cisco
show ip ssh
show running-config | section line vty
```

> La contraseña real no debe guardarse en GitHub.

### Compatibilidad desde OpenSSH moderno

El Catalyst 2960 puede ofrecer algoritmos SSH antiguos. Desde PowerShell se utilizó, cuando fue necesario:

```powershell
ssh -oKexAlgorithms=+diffie-hellman-group14-sha1 -oHostKeyAlgorithms=+ssh-rsa admin@192.168.10.2
```

Este comando se ejecuta en el cliente, no forma parte de la configuración del switch.

---

## 3.8 SNMPv2c para Zabbix

Servidor autorizado:

```text
192.168.40.11
```

Crear ACL:

```cisco
configure terminal
access-list 10 permit host 192.168.40.11
```

Configurar comunidad SNMP únicamente de lectura:

```cisco
snmp-server community <SNMP_COMMUNITY_RO> RO 10
```

Información opcional del equipo:

```cisco
snmp-server location Proyecto-Integrador-G3
snmp-server contact Equipo-G3
```

Finalizar:

```cisco
end
```

Verificación:

```cisco
show snmp
show running-config | include snmp
show access-lists 10
```

> `<SNMP_COMMUNITY_RO>` debe reemplazarse localmente por la comunidad configurada. No guardar el valor real en un repositorio público.

---

## 3.9 Guardar configuración del Cisco

```cisco
copy running-config startup-config
```

Aceptar el nombre predeterminado:

```text
Destination filename [startup-config]?
```

Presionar **Enter**.

Verificación:

```cisco
show startup-config
```

---

# 4. Comandos generales de evidencia

## MikroTik

```routeros
/interface vlan print
/interface ethernet print
/interface print
/ip address print
/interface list member print
/ip route print
/ip firewall nat print stats
/ip firewall filter print
/ip pool print
/ip dhcp-server print
/ip dhcp-server network print
/ip dhcp-server lease print
/ip service print
/snmp print
/snmp community print detail
```

## Cisco

Antes de obtener salidas largas:

```cisco
terminal length 0
```

Evidencias:

```cisco
show vlan brief
show interfaces trunk
show interfaces status
show ip interface brief
show running-config interface GigabitEthernet0/1
show running-config interface GigabitEthernet0/2
show running-config interface FastEthernet0/2
show running-config | section interface
show ip ssh
show running-config | section line vty
show snmp
show running-config | include snmp
show access-lists 10
```

---

# 5. Pruebas realizadas

## VLAN 10 — Administración

Ejemplo de dirección de prueba:

```text
IP:      192.168.10.10/24
Gateway: 192.168.10.1
```

Pruebas:

```cmd
ping 192.168.10.1
ping 192.168.10.2
ping 1.1.1.1
```

Resultados esperados:

```text
192.168.10.1 → responde
192.168.10.2 → responde
1.1.1.1      → responde
```

## VLAN 60 — Usuarios

Ejemplo:

```text
IP:      192.168.60.10/24
Gateway: 192.168.60.1
```

Pruebas:

```cmd
ping 192.168.60.1
ping 1.1.1.1
ping 192.168.10.2
ping 192.168.30.10
```

Resultados esperados:

```text
192.168.60.1  → responde
1.1.1.1       → responde
192.168.10.2  → bloqueado
192.168.30.10 → bloqueado
```

Estas pruebas validan gateway, NAT/PAT y aislamiento de Usuarios hacia Administración y Base de Datos.
