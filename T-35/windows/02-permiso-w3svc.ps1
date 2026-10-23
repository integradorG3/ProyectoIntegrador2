<#
 VM-02. Ejecutar como ADMINISTRADOR. Da a n8n-remed permiso SOLO sobre el servicio W3SVC
 (consultar estado, iniciar y detener), sin hacerlo administrador.

 ADVERTENCIA: el descriptor de seguridad (SDDL) debe validarse en la VM real antes de activar la
 remediacion de Windows en n8n (ver README, seccion "Validar IIS"). Este script guarda una copia del
 SDDL original para poder revertir, y no cambia nada si el permiso ya existe.

 Derechos concedidos: CC (consultar configuracion) + LC (consultar estado) + SW (enumerar servicios dependientes) + LO (interrogar)
 + RP (iniciar) + WP (detener) + RC (leer permisos). SW y CC son de solo lectura; Restart-Service puede pedirlos.
 Uso:  .\02-permiso-w3svc.ps1            (aplica)
       .\02-permiso-w3svc.ps1 -Revertir   (restaura el SDDL guardado)
#>
param(
    [string]$Usuario = "n8n-remed",
    [string]$Servicio = "W3SVC",
    [switch]$Revertir
)
$ErrorActionPreference = "Stop"
$respaldo = Join-Path $PSScriptRoot "sddl-original-$Servicio.txt"

if ($Revertir) {
    $original = (Get-Content $respaldo -Raw).Trim()
    sc.exe sdset $Servicio $original | Out-Host
    sc.exe sdshow $Servicio | Out-Host
    return
}

$sid = (New-Object System.Security.Principal.NTAccount($Usuario)).Translate([System.Security.Principal.SecurityIdentifier]).Value
$actual = ((sc.exe sdshow $Servicio) -join "").Trim()
if (-not $actual.StartsWith("D:")) { throw "Salida inesperada de sc sdshow: $actual" }
if (-not (Test-Path $respaldo)) { Set-Content -Path $respaldo -Value $actual -Encoding ascii }

if ($actual -match [regex]::Escape(";;;$sid)")) {
    Write-Host "El permiso para $Usuario ya existe. No se cambia nada."
} else {
    $ace = "(A;;CCLCSWLORPWPRC;;;$sid)"
    # El DACL termina donde empieza la seccion S: (SACL); si no hay SACL, va al final de la cadena.
    $i = $actual.IndexOf("S:")
    $nuevo = if ($i -ge 0) { $actual.Insert($i, $ace) } else { $actual + $ace }
    sc.exe sdset $Servicio $nuevo | Out-Host
}
Write-Host "SDDL actual:"; sc.exe sdshow $Servicio | Out-Host
Write-Host "Respaldo del original: $respaldo (no subirlo a GitHub)"
