$version = "1.0.0"
Write-Host "PC Setup v$version" -ForegroundColor Cyan

Start-Transcript -Path "$env:TEMP\pc-setup-log.txt"

# Admin check
if (-not ([Security.Principal.WindowsPrincipal] `
[Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole("Administrator")) {
    Write-Host "Ejecuta como administrador" -ForegroundColor Red
    exit
}

$base = "https://raw.githubusercontent.com/TUUSUARIO/TUREPO/main/modules"

Write-Host "Descargando módulos..." -ForegroundColor Yellow

Invoke-Expression (Invoke-WebRequest "$base/apps.ps1").Content
Invoke-Expression (Invoke-WebRequest "$base/browsers.ps1").Content
Invoke-Expression (Invoke-WebRequest "$base/windows.ps1").Content
Invoke-Expression (Invoke-WebRequest "$base/office.ps1").Content
Invoke-Expression (Invoke-WebRequest "$base/tweaks.ps1").Content

Write-Host "INSTALACION COMPLETADA" -ForegroundColor Green

Stop-Transcript