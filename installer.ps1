# 1. Comprobar administrador compatible con scripts en memoria (IEX)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Reejecutando con privilegios de Administrador..."
    # Como $PSCommandPath no existe en IEX, volvemos a lanzar el comando original apuntando a tu GitHub
    $remoteCommand = "irm https://raw.githubusercontent.com/izanvinolo23-alt/basicaPC/main/installer.ps1 | iex"
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$remoteCommand`"" -Verb RunAs
    Exit
}

# 2. Configuración de entorno y registro
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
$version = "1.0.0"
Write-Host "PC Setup v$version" -ForegroundColor Cyan

Start-Transcript -Path "$env:TEMP\pc-setup-log.txt"

# 3. Descarga e inicio de módulos
# Cambia 'TUUSUARIO/TUREPO' por tus datos reales si los separas en carpetas
$base = "https://raw.githubusercontent.com/izanvinolo23-alt/basicaPC/main/modules"

Write-Host "Descargando módulos desde GitHub..." -ForegroundColor Yellow

# Usamos Invoke-RestMethod (irm) que es más limpio y rápido que Invoke-WebRequest
Invoke-Expression (Invoke-RestMethod "$base/apps.ps1")
Invoke-Expression (Invoke-RestMethod "$base/browsers.ps1")
Invoke-Expression (Invoke-RestMethod "$base/windows.ps1")
Invoke-Expression (Invoke-RestMethod "$base/office.ps1")
Invoke-Expression (Invoke-RestMethod "$base/tweaks.ps1")

Write-Host "INSTALACIÓN COMPLETADA" -ForegroundColor Green

Stop-Transcript

# 4. Pausa obligatoria para que no se cierre la ventana al ejecutar desde la nube
Read-Host "Presiona ENTER para finalizar y cerrar la ventana"
