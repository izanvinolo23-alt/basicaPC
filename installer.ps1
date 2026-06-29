# ==============================================================================
# PC SETUP UNIFICADO - TODO EN UNO
# ==============================================================================

# 1. FORZAR ADMINISTRADOR (Compatible con IEX)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Reejecutando con privilegios de Administrador..."
    $remoteCommand = "irm https://raw.githubusercontent.com/izanvinolo23-alt/basicaPC/main/installer.ps1 | iex"
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$remoteCommand`"" -Verb RunAs
    Exit
}

# 2. CONFIGURACIÓN DE ENTORNO Y RED SEGURA
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$version = "1.1.0"
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "         PC Setup Unificado v$version        " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

Start-Transcript -Path "$env:TEMP\pc-setup-log.txt"

# Asegurar que winget está disponible en la sesión actual
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}


# ==========================================
# BLOQUE 1: INSTALACIÓN DE APPS (Winget)
# ==========================================
Write-Host "`n[1/5] Instalando aplicaciones esenciales..." -ForegroundColor Cyan
$apps = @("Google.Chrome", "Mozilla.Firefox", "VideoLAN.VLC", "Adobe.Acrobat.Reader.64-bit")

foreach ($app in $apps) {
    Write-Host "-> Instalando: $app..." -ForegroundColor Yellow
    try {
        winget install --id $app --silent --accept-package-agreements --accept-source-agreements --exact --override "/qn"
        Write-Host "[OK] $app procesado." -ForegroundColor Green
    } catch {
        Write-Error "Error al intentar instalar $app : $_"
    }
}


# ==========================================
# BLOQUE 2: POLÍTICAS DE NAVEGADORES
# ==========================================
Write-Host "`n[2/5] Configurando políticas de navegadores (Google.cat)..." -ForegroundColor Cyan

# Edge & Chrome (Registro)
$paths = @("HKLM:\SOFTWARE\Policies\Microsoft\Edge", "HKLM:\SOFTWARE\Policies\Google\Chrome")
foreach ($p in $paths) {
    if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
    Set-ItemProperty -Path $p -Name "HomepageLocation" -Value "https://www.google.cat" -Force
    Set-ItemProperty -Path $p -Name "RestoreOnStartup" -Value 4 -Force
    
    $urlsP = "$p\RestoreOnStartupURLs"
    if (-not (Test-Path $urlsP)) { New-Item -Path $urlsP -Force | Out-Null }
    Set-ItemProperty -Path $urlsP -Name "1" -Value "https://www.google.cat" -Force
    
    Set-ItemProperty -Path $p -Name "DefaultSearchProviderEnabled" -Value 1 -Force
    Set-ItemProperty -Path $p -Name "DefaultSearchProviderName" -Value "Google" -Force
    Set-ItemProperty -Path $p -Name "DefaultSearchProviderSearchURL" -Value "https://www.google.cat/search?q={searchTerms}" -Force
}

# Firefox (JSON corporativo)
$ffDir = "C:\Program Files\Mozilla Firefox\distribution"
if (-not (Test-Path $ffDir)) { New-Item -ItemType Directory -Path $ffDir -Force | Out-Null }
@'
{
  "policies": {
    "Homepage": { "URL": "https://www.google.cat", "StartPage": "homepage", "Locked": true },
    "SearchEngines": { "Default": "Google", "PreventInstalls": true, "Remove": ["Bing", "Yahoo", "DuckDuckGo", "eBay", "Wikipedia (es)"] }
  }
}
'@ | Out-File -FilePath "$ffDir\policies.json" -Encoding utf8 -Force
Write-Host "[OK] Navegadores vinculados a Google.cat." -ForegroundColor Green


# ==========================================
# BLOQUE 3: OPTIMIZACIÓN DE SERVICIOS
# ==========================================
Write-Host "`n[3/5] Optimizando servicios del sistema..." -ForegroundColor Cyan
$services = @("DiagTrack", "dmwappushservice", "XblGameSave", "XblAuthManager", "XboxNetApiSvc", "XboxGipSvc", "WSearch", "WerSvc", "MapsBroker", "ParentalControls")
$protegidos = @("WinDefend", "Sense", "WdNisSvc", "SecurityHealthService")

foreach ($s in $services) {
    if ((Get-Service $s -ErrorAction SilentlyContinue) -and ($s -notin $protegidos)) {
        Stop-Service $s -Force -ErrorAction SilentlyContinue
        reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\$s" /v Start /t REG_DWORD /d 4 /f | Out-Null
    }
}
Write-Host "[OK] Servicios innecesarios deshabilitados de raíz." -ForegroundColor Green


# ==========================================
# BLOQUE 4: LIMPIEZA DE ARRANQUE (Startup)
# ==========================================
Write-Host "`n[4/5] Limpiando software de arranque innecesario..." -ForegroundColor Cyan
bcdedit /deletevalue {current} numproc -ErrorAction SilentlyContinue | Out-Null
$runPaths = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run")
$whitelist = @("SecurityHealth", "WindowsDefender", "OneDrive", "RtkAudUService")

foreach ($path in $runPaths) {
    if (Test-Path $path) {
        foreach ($prop in (Get-Item $path).Property) {
            if ($prop -notin $whitelist) {
                Remove-ItemProperty -Path $path -Name $prop -ErrorAction SilentlyContinue
            }
        }
    }
}
Write-Host "[OK] Inicio limpio. CPU optimizada al 100% de fábrica." -ForegroundColor Green


# ==========================================
# BLOQUE 5: DESCARGAS DE SOPORTE (Supremo)
# ==========================================
Write-Host "`n[5/5] Descargando herramientas de soporte técnico..." -ForegroundColor Cyan
# Desactivar animaciones visuales
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "AnimateControls" -Value 0 -Force

# Descargar Supremo al escritorio visible de todos los usuarios
try {
    Invoke-WebRequest -Uri "https://www.supremocontrol.com/download/Supremo.exe" -OutFile "$env:PUBLIC\Desktop\Supremo.exe" -ErrorAction Stop
    Write-Host "[OK] Supremo descargado en el Escritorio Público." -ForegroundColor Green
} catch {
    Write-Warning "No se pudo descargar Supremo de forma automatizada: $_"
}


# ==========================================
# FINALIZACIÓN
# ==========================================
Write-Host "`n-------------------------------------------------" -ForegroundColor Gray
Write-Host "PROCESO DE INSTALACIÓN COMPLETO CON ÉXITO" -ForegroundColor Green
Write-Host "-------------------------------------------------" -ForegroundColor Gray
Stop-Transcript

Read-Host "Presiona ENTER para finalizar y cerrar esta ventana"
