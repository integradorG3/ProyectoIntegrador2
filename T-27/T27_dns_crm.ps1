# REAL T-27 - Registros DNS de ambos CRM
# Proyecto Integrador - Grupo 03
# Ejecutar en el servidor DNS/AD DS con PowerShell como administrador.

Add-DnsServerResourceRecordA `
    -Name "crm01" `
    -ZoneName "g3.test" `
    -IPv4Address "192.168.20.11"

Add-DnsServerResourceRecordA `
    -Name "crm02" `
    -ZoneName "g3.test" `
    -IPv4Address "192.168.20.12"
