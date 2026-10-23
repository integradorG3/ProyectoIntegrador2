<#
 VM-02 (Windows Server / IIS). Ejecutar en PowerShell COMO ADMINISTRADOR.
 Instala y habilita OpenSSH Server, crea la cuenta local limitada n8n-remed
 y registra la llave PUBLICA de n8n. No guarda ninguna clave en este archivo.

 Uso:  .\01-openssh-n8n-remed.ps1 -LlavePublica "ssh-ed25519 AAAA... n8n@vm-07"
#>
param(
    [Parameter(Mandatory = $true)][string]$LlavePublica,
    [string]$Usuario = "n8n-remed",
    [string]$IpN8n = "192.168.50.11"
)
$ErrorActionPreference = "Stop"

# 1) OpenSSH Server
if ((Get-WindowsCapability -Online -Name "OpenSSH.Server*").State -ne "Installed") {
    Add-WindowsCapability -Online -Name "OpenSSH.Server~~~~0.0.1.0" | Out-Null
}
Set-Service -Name sshd -StartupType Automatic
Start-Service sshd

# 2) Regla de firewall de Windows: solo VM-07 (n8n) llega al puerto 22
Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -Name "OpenSSH-n8n" -DisplayName "OpenSSH Server (solo n8n)" -Direction Inbound `
    -Protocol TCP -LocalPort 22 -RemoteAddress $IpN8n -Action Allow | Out-Null

# 3) Cuenta local limitada (NO administrador). La clave de la cuenta se pide aqui y no se guarda.
if (-not (Get-LocalUser -Name $Usuario -ErrorAction SilentlyContinue)) {
    $clave = Read-Host "Clave para la cuenta $Usuario (no se muestra ni se guarda)" -AsSecureString
    New-LocalUser -Name $Usuario -Password $clave -PasswordNeverExpires -UserMayNotChangePassword `
        -Description "Cuenta limitada para remediacion desde n8n (solo reiniciar W3SVC)" | Out-Null
}

# 4) Llave publica de n8n. Para usuarios que no son administradores va en el perfil del usuario.
#    El perfil se crea al primer inicio de sesion; se fuerza una vez con RunAs si no existe.
$perfil = "C:\Users\$Usuario"
if (-not (Test-Path $perfil)) {
    Write-Host "El perfil de $Usuario no existe todavia. Inicie sesion una vez con esa cuenta (runas /user:$Usuario cmd) y vuelva a ejecutar este script."
    exit 1
}
$dirSsh = Join-Path $perfil ".ssh"
New-Item -ItemType Directory -Path $dirSsh -Force | Out-Null
$archivo = Join-Path $dirSsh "authorized_keys"
if (-not (Test-Path $archivo) -or -not (Select-String -Path $archivo -SimpleMatch $LlavePublica -Quiet)) {
    Add-Content -Path $archivo -Value $LlavePublica -Encoding ascii
}
# Permisos estrictos exigidos por OpenSSH: solo SYSTEM, Administradores y el propio usuario
icacls $archivo /inheritance:r /grant "SYSTEM:F" /grant "BUILTIN\Administrators:F" /grant "${Usuario}:R" | Out-Null

Restart-Service sshd
Write-Host "Listo. Pruebe desde VM-07:  ssh -i <llave> $Usuario@192.168.20.12 whoami"
