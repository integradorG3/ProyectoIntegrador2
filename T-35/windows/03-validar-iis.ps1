<#
 VM-02. Prueba controlada del reinicio de IIS. Ejecutar como ADMINISTRADOR en la VM-02,
 en una ventana de mantenimiento acordada (el CRM B queda caido unos segundos).
 Mide cuanto tarda el servicio en volver a responder por HTTP. No requiere n8n.
#>
param([string]$Url = "http://192.168.20.12", [string]$Servicio = "W3SVC")
$ErrorActionPreference = "Stop"
function Http-Ok { try { (Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5).StatusCode -lt 400 } catch { $false } }

"{0}  Estado inicial: {1} | HTTP OK: {2}" -f (Get-Date -Format s), (Get-Service $Servicio).Status, (Http-Ok)
$t0 = Get-Date
Stop-Service $Servicio -Force
"{0}  Servicio detenido (simula la caida) | HTTP OK: {1}" -f (Get-Date -Format s), (Http-Ok)
$t1 = Get-Date
Start-Service $Servicio
$limite = (Get-Date).AddSeconds(120)
while (-not (Http-Ok) -and (Get-Date) -lt $limite) { Start-Sleep -Seconds 2 }
$t2 = Get-Date
"{0}  Estado final: {1} | HTTP OK: {2}" -f (Get-Date -Format s), (Get-Service $Servicio).Status, (Http-Ok)
"Tiempo de recuperacion (inicio del servicio hasta HTTP OK): {0:N1} s" -f ($t2 - $t1).TotalSeconds
