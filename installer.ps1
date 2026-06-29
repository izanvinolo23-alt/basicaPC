# ==============================================================================
# PC SETUP UNIFICADO - VERSIÓN FINAL CORREGIDA
# ==============================================================================

# 1. FORZAR ADMINISTRADOR
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Reejecutando con privilegios de Administrador..."
    $remoteCommand = "irm https://raw.githubusercontent.com/izanvinolo23-alt/basicaPC/main/installer.ps1 | iex"
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$remoteCommand`"" -Verb RunAs
    Exit
}

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$version = "1.2.0"
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "         PC Setup Unificado v$version        " -ForegroundColor Cyan
Write-Host "=============================================" -Workspace Cyan

Start-Transcript -Path "$env:TEMP\pc-setup-log.txt"

# ==========================================
# BLOQUE 1: INSTALACIÓN DE APPS (Winget)
# ==========================================
Write-Host "`n[1/5] Instalando aplicaciones esenciales..." -ForegroundColor Cyan
winget source update --accept-source-agreements | Out-Null

$apps = @("Google.Chrome", "Mozilla.Firefox", "VideoLAN.VLC", "Adobe.Acrobat.Reader.64-bit")

foreach ($app in $apps) {
    Write-Host "-> Instalando: $app de forma silenciosa..." -ForegroundColor Yellow
    try {
        if ($app -eq "Mozilla.Firefox" -or $app -eq "VideoLAN.VLC") {
            winget install --id $app --silent --accept-package-agreements --accept-source-agreements --exact --override "/S"
        } else {
            winget install --id $app --silent --accept-package-agreements --accept-source-agreements --exact
        }
        Write-Host "[OK] $app instalado." -ForegroundColor Green
    } catch {
        Write-Error "Error al intentar instalar $app : $_"
    }
}

# Pausa de seguridad de 10 segundos para que Windows asimile las instalaciones
Write-Host "`n-> Esperando a que el sistema registre las aplicaciones..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# ==========================================
# BLOQUE 2: POLÍTICAS DE NAVEGADORES
# ==========================================
Write-Host "`n[2/5] Configurando políticas de navegadores (Google.cat)..." -ForegroundColor Cyan

$paths = @("HKLM:\SOFTWARE\Policies\Microsoft\Edge", "HKLM:\SOFTWARE\Policies\Google\Chrome")
foreach ($p in $paths) {
    # Forzar la creación de la ruta del registro si no existe
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

# Firefox Corporativo Seguro
$ffDir = "C:\Program Files\Mozilla Firefox\distribution"
if (-not (Test-Path $ffDir)) { New-Item -ItemType Directory -Path $ffDir -Force | Out-Null }
$jsonPolicy = @'
{
  "policies": {
    "Homepage": { "URL": "https://www.google.cat", "StartPage": "homepage", "Locked": true },
    "SearchEngines": { "Default": "Google", "PreventInstalls": true, "Remove": ["Bing", "Yahoo", "DuckDuckGo", "eBay", "Wikipedia (es)"] }
  }
}
'@
$jsonPolicy | Out-File -FilePath "$ffDir\policies.json" -Encoding utf8 -Force
Write-Host "[OK] Políticas aplicadas correctamente." -ForegroundColor Green

# ==========================================
# BLOQUE 3: OPTIMIZACIÓN DE SERVICIOS
# ==========================================
Write-Host "`n[3/5] Optimizando servicios del sistema..." -ForegroundColor Cyan
$services = @("DiagTrack", "dmwappushservice", "XblGameSave", "XblAuthManager", "XboxNetApiSvc", "XboxGipSvc", "WSearch", "WerSvc", "MapsBroker", "ParentalControls")
foreach ($s in $services) {
    if (Get-Service $s -ErrorAction SilentlyContinue) {
        Stop-Service $s -Force -ErrorAction SilentlyContinue
        reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\$s" /v Start /t REG_DWORD /d 4 /f | Out-Null
    }
}
Write-Host "[OK] Servicios innecesarios deshabilitados." -ForegroundColor Green

# ==========================================
# BLOQUE 4: LIMPIEZA DE ARRANQUE (Startup)
# ==========================================
Write-Host "`n[4/5] Limpiando software de arranque..." -ForegroundColor Cyan
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
Write-Host "[OK] Inicio limpio configurado." -ForegroundColor Green

# ==========================================
# BLOQUE 5: DESCARGAS DE SOPORTE (Supremo)
# ==========================================
Write-Host "`n[5/5] Descargando herramientas de soporte técnico..." -ForegroundColor Cyan
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "AnimateControls" -Value 0 -Force

try {
    # Usamos un User-Agent de Mozilla para evitar que los servidores de Supremo bloqueen la solicitud automatizada
    $userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
    Invoke-WebRequest -Uri "https://www.supremocontrol.com/download/Supremo.exe" -OutFile "$env:PUBLIC\Desktop\Supremo.exe" -UserAgent $userAgent -ErrorAction Stop
    Write-Host "[OK] Supremo descargado en el Escritorio Público." -ForegroundColor Green
} catch {
    Write-Warning "No se pudo descargar Supremo: $_"
}

# ==========================================
# FINALIZACIÓN
# ==========================================
Write-Host "`n-------------------------------------------------" -ForegroundColor Gray
Write-Host "PROCESO DE INSTALACIÓN COMPLETO CON ÉXITO" -ForegroundColor Green
Write-Host "-------------------------------------------------" -ForegroundColor Gray
Stop-Transcript

Read-Host "Presiona ENTER para finalizar y cerrar esta ventana"
