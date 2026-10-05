# oct/05/2026 10:52:32 by RouterOS 6.46.8
# software id = STC0-KK3T
#
# model = RB3011UiAS
# serial number = E7EA0E3F593F
/interface bridge
add admin-mac=2C:C8:1B:71:75:B9 auto-mac=no comment=defconf name=bridge
/interface vlan
add interface=ether3 name=vlan10-admin vlan-id=10
add interface=ether3 name=vlan20-app vlan-id=20
add interface=ether3 name=vlan30-db vlan-id=30
add interface=ether3 name=vlan40-servicios vlan-id=40
add interface=ether3 name=vlan50-auto vlan-id=50
add interface=ether3 name=vlan60-usuarios vlan-id=60
/interface list
add comment=defconf name=WAN
add comment=defconf name=LAN
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/ip pool
add name=default-dhcp ranges=192.168.88.10-192.168.88.254
add name=pool-vlan60 ranges=192.168.60.10-192.168.60.245
add name=pool-vlan10 ranges=192.168.10.15-192.168.10.25
/ip dhcp-server
add address-pool=default-dhcp disabled=no interface=bridge name=defconf
add address-pool=pool-vlan60 disabled=no interface=vlan60-usuarios \
    lease-time=1d name=dhcp-vlan60
add address-pool=pool-vlan10 disabled=no interface=vlan10-admin lease-time=1d \
    name=dhcp-vlan10
/snmp community
add addresses=192.168.40.11/32 name=G3_ZABBIX_RO
/interface bridge port
add bridge=bridge comment=defconf interface=ether4
add bridge=bridge comment=defconf interface=ether5
add bridge=bridge comment=defconf interface=ether6
add bridge=bridge comment=defconf interface=ether7
add bridge=bridge comment=defconf interface=ether8
add bridge=bridge comment=defconf interface=ether9
add bridge=bridge comment=defconf interface=ether10
add bridge=bridge comment=defconf interface=sfp1
/ip neighbor discovery-settings
set discover-interface-list=LAN
/interface list member
add comment=defconf interface=bridge list=LAN
add comment=defconf interface=ether2 list=WAN
add comment=vlan10-admin interface=vlan10-admin list=LAN
add comment=vlan20-app interface=vlan20-app list=LAN
add comment=vlan30-db interface=vlan30-db list=LAN
add comment=vlan40-servicios interface=vlan40-servicios list=LAN
add comment=vlan50-auto interface=vlan50-auto list=LAN
add comment=vlan60-usuarios interface=vlan60-usuarios list=LAN
/ip address
add address=192.168.88.1/24 comment=defconf interface=bridge network=\
    192.168.88.0
add address=192.168.10.1/24 comment=vlan10-admin interface=vlan10-admin \
    network=192.168.10.0
add address=192.168.20.1/24 comment=vlan20-app interface=vlan20-app network=\
    192.168.20.0
add address=192.168.30.1/24 comment=vlan30-db interface=vlan30-db network=\
    192.168.30.0
add address=192.168.40.1/24 comment=vlan40-servicios interface=\
    vlan40-servicios network=192.168.40.0
add address=192.168.50.1/24 comment=vlan50-auto interface=vlan50-auto \
    network=192.168.50.0
add address=192.168.60.1/24 comment=vlan60-usuarios interface=vlan60-usuarios \
    network=192.168.60.0
/ip dhcp-client
add comment=defconf disabled=no interface=ether2 use-peer-ntp=no
/ip dhcp-server network
add address=192.168.10.0/24 dns-server=8.8.8.8 gateway=192.168.10.1
add address=192.168.60.0/24 dns-server=8.8.8.8 gateway=192.168.60.1
add address=192.168.88.0/24 comment=defconf gateway=192.168.88.1
/ip dns
set allow-remote-requests=yes
/ip dns static
add address=192.168.88.1 comment=defconf name=router.lan
/ip firewall filter
add action=accept chain=input comment=\
    "defconf: accept established,related,untracked" connection-state=\
    established,related,untracked
add action=drop chain=input comment="defconf: drop invalid" connection-state=\
    invalid
add action=accept chain=input comment="defconf: accept ICMP" protocol=icmp
add action=accept chain=input comment=\
    "defconf: accept to local loopback (for CAPsMAN)" dst-address=127.0.0.1
add action=accept chain=forward comment="defconf: accept in ipsec policy" \
    ipsec-policy=in,ipsec
add action=accept chain=forward comment="defconf: accept out ipsec policy" \
    ipsec-policy=out,ipsec
add action=accept chain=forward comment=PERMITIR-DNS-ADDS-USUARIOS-UDP \
    dst-address=192.168.10.10 dst-port=53 protocol=udp src-address=\
    192.168.60.0/24
add action=accept chain=forward comment=PERMITIR-DNS-ADDS-USUARIOS-TCP \
    dst-address=192.168.10.10 dst-port=53 protocol=tcp src-address=\
    192.168.60.0/24
add action=drop chain=forward comment=BLOQUEAR-USUARIOS-A-ADMIN dst-address=\
    192.168.10.0/24 src-address=192.168.60.0/24
add action=drop chain=forward comment=BLOQUEAR-USUARIOS-A-BD dst-address=\
    192.168.30.0/24 src-address=192.168.60.0/24
add action=drop chain=forward comment=BLOQUEAR-USUARIOS-A-RED-LEGACY \
    dst-address=192.168.88.0/24 src-address=192.168.60.0/24
add action=fasttrack-connection chain=forward comment="defconf: fasttrack" \
    connection-state=established,related
add action=accept chain=forward comment=\
    "defconf: accept established,related, untracked" connection-state=\
    established,related,untracked
add action=drop chain=forward comment="defconf: drop invalid" \
    connection-state=invalid
add action=drop chain=forward comment=\
    "defconf: drop all from WAN not DSTNATed" connection-nat-state=!dstnat \
    connection-state=new in-interface-list=WAN
add action=accept chain=input comment="DNS VLAN60 UDP" dst-port=53 protocol=\
    udp src-address=192.168.60.0/24
add action=accept chain=input comment="DNS VLAN60 TCP" dst-port=53 protocol=\
    tcp src-address=192.168.60.0/24
add action=drop chain=input comment="defconf: drop all not coming from LAN" \
    in-interface-list=!LAN
/ip firewall nat
add action=masquerade chain=srcnat comment="defconf: masquerade" \
    ipsec-policy=out,none out-interface-list=WAN
/ip service
set ssh address=192.168.88.0/24,192.168.10.0/24
set winbox address=192.168.88.0/24,192.168.10.0/24
/ip ssh
set strong-crypto=yes
/snmp
set enabled=yes
/system clock
set time-zone-name=America/Costa_Rica
/tool mac-server
set allowed-interface-list=LAN
/tool mac-server mac-winbox
set allowed-interface-list=LAN
