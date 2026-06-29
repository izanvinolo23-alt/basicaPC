# ==============================================================================
# PC SETUP - SCRIPT PRINCIPAL
# ==============================================================================

# 1. Forzar ejecución como Administrador compatible con ejecución en memoria (IEX)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Reejecutando con privilegios de Administrador..."
    $remoteCommand = "irm https://raw.githubusercontent.com/izanvinolo23-alt/basicaPC/main/installer.ps1 | iex"
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$remoteCommand`"" -Verb RunAs
    Exit
}

# 2. Configuración de entorno y protocolos de red seguros
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$version = "1.0.0"
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "            PC Setup v$version               " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Iniciar registro de volcado de texto para auditoría
Start-Transcript -Path "$env:TEMP\pc-setup-log.txt"

Write-Host "Descargando y ejecutando módulos desde GitHub..." -ForegroundColor Yellow
Write-Host "-------------------------------------------------" -ForegroundColor Gray

# 3. Descarga e Invocación Estricta de Módulos (URLs Absolutas)
try { 
    Invoke-Expression (Invoke-RestMethod -Uri "https://raw.githubusercontent.com/izanvinolo23-alt/basicaPC/main/modules/apps.ps1" -ErrorAction Stop)
    Write-Host "[OK] Módulo 'apps' ejecutado." -ForegroundColor Green 
} catch { Write-Error "Fallo crítico en apps.ps1: $_" }

try { 
    Invoke-Expression (Invoke-RestMethod -Uri "https://raw.githubusercontent.com/izanvinolo23-alt/basicaPC/main/modules/browsers.ps1" -ErrorAction Stop)
    Write-Host "[OK] Módulo 'browsers' ejecutado." -ForegroundColor Green 
} catch { Write-Error "Fallo crítico en browsers.ps1: $_" }

try { 
    Invoke-Expression (Invoke-RestMethod -Uri "https://raw.githubusercontent.com/izanvinolo23-alt/basicaPC/main/modules/windows.ps1" -ErrorAction Stop)
    Write-Host "[OK] Módulo 'windows' ejecutado." -ForegroundColor Green 
} catch { Write-Error "Fallo crítico en windows.ps1: $_" }

try { 
    Invoke-Expression (Invoke-RestMethod -Uri "https://raw.githubusercontent.com/izanvinolo23-alt/basicaPC/main/modules/office.ps1" -ErrorAction Stop)
    Write-Host "[OK] Módulo 'office' ejecutado." -ForegroundColor Green 
} catch { Write-Error "Fallo crítico en office.ps1: $_" }

try { 
    Invoke-Expression (Invoke-RestMethod -Uri "https://raw.githubusercontent.com/izanvinolo23-alt/basicaPC/main/modules/tweaks.ps1" -ErrorAction Stop)
    Write-Host "[OK] Módulo 'tweaks' ejecutado." -ForegroundColor Green 
} catch { Write-Error "Fallo crítico en tweaks.ps1: $_" }

# 4. Finalización del proceso
Write-Host "-------------------------------------------------" -ForegroundColor Gray
Write-Host "PROCESO DE INSTALACIÓN COMPLETO" -ForegroundColor Green

Stop-Transcript
Write-Host "Log guardado en: $env:TEMP\pc-setup-log.txt" -ForegroundColor DarkGray

# Pausa obligatoria para que la ventana no se cierre sola
Read-Host "Presiona ENTER para finalizar y cerrar la ventana"
