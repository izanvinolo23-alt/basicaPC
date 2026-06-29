# ==============================================================================
# PC SETUP UNIFICADO - MENÚ INTERACTIVO (OPCIÓN 1: INSTALAR TODO)
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

# Asegurar que winget está disponible
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Funciones de soporte
function Instalar-Navegadores {
    Write-Host "`n[+] Instalando aplicaciones esenciales (Chrome, Firefox, VLC, Adobe)..." -ForegroundColor Cyan
    winget source update --accept-source-agreements | Out-Null
    $apps = @("Google.Chrome", "Mozilla.Firefox", "VideoLAN.VLC", "Adobe.Acrobat.Reader.64-bit")
    foreach ($app in $apps) {
        Write-Host "-> Instalando: $app de forma silenciosa..." -ForegroundColor Yellow
        if ($app -eq "Mozilla.Firefox" -or $app -eq "VideoLAN.VLC") {
            winget install --id $app --silent --accept-package-agreements --accept-source-agreements --exact --override "/S"
        } else {
            winget install --id $app --silent --accept-package-agreements --accept-source-agreements --exact
        }
    }
    Write-Host "[OK] Aplicaciones base procesadas." -ForegroundColor Green
}

function Configurar-Navegadores {
    Write-Host "`n[+] Configurando políticas de navegación (Google.cat)..." -ForegroundColor Cyan
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
    $ffDir = "C:\Program Files\Mozilla Firefox\distribution"
    if (-not (Test-Path $ffDir)) { New-Item -ItemType Directory -Path $ffDir -Force | Out-Null }
    '{"policies":{"Homepage":{"URL":"https://www.google.cat","StartPage":"homepage","Locked":true},"SearchEngines":{"Default":"Google","PreventInstalls":true,"Remove":["Bing","Yahoo","DuckDuckGo","eBay"]}}}' | Out-File -FilePath "$ffDir\policies.json" -Encoding utf8 -Force
    Write-Host "[OK] Navegadores vinculados a Google.cat." -ForegroundColor Green
}

function Instalar-Office {
    Write-Host "`n[+] Iniciando instalación automatizada de Microsoft Office 2021..." -ForegroundColor Cyan
    $officeTemp = "$env:TEMP\OfficeSetup"
    if (-not (Test-Path $officeTemp)) { New-Item -ItemType Directory -Path $officeTemp -Force | Out-Null }
    try {
        $odtUrl = "https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB029D4A9D/officedeploymenttool_17628-20164.exe"
        Invoke-WebRequest -Uri $odtUrl -OutFile "$officeTemp\odt.exe" -ErrorAction Stop
        Start-Process -FilePath "$officeTemp\odt.exe" -ArgumentList "/extract:`"$officeTemp`" /quiet" -Wait
        $xmlContent = '<Configuration><Add OfficeClientEdition="64" Channel="PerpetualVL2021"><Product ID="ProPlus2021Volume"><Language ID="es-es" /><ExcludeApp ID="Lync" /><ExcludeApp ID="OneDrive" /><ExcludeApp ID="OneNote" /></Product></Add><Display Level="None" AcceptEULA="TRUE" /><Property Name="AUTOACTIVATE" Value="1" /></Configuration>'
        $xmlContent | Out-File -FilePath "$officeTemp\configuration.xml" -Encoding utf8 -Force
        Write-Host "-> Descargando e instalando Office (Espera unos minutos)..." -ForegroundColor Yellow
        Start-Process -FilePath "$officeTemp\setup.exe" -ArgumentList "/configure `"$officeTemp\configuration.xml`"" -Wait
        Write-Host "[OK] Microsoft Office instalado correctamente." -ForegroundColor Green
    } catch { Write-Error "Fallo en Office: $_" }
}

function Optimizar-Sistema {
    Write-Host "`n[+] Aplicando optimizaciones y limpieza del sistema..." -ForegroundColor Cyan
    # Deshabilitar servicios innecesarios
    $services = @("DiagTrack", "dmwappushservice", "XblGameSave", "XblAuthManager", "XboxNetApiSvc", "XboxGipSvc", "WSearch", "WerSvc", "MapsBroker", "ParentalControls")
    foreach ($s in $services) {
        if (Get-Service $s -ErrorAction SilentlyContinue) {
            Stop-Service $s -Force -ErrorAction SilentlyContinue
            reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\$s" /v Start /t REG_DWORD /d 4 /f | Out-Null
        }
    }
    # Limpieza de arranque
    bcdedit /deletevalue {current} numproc -ErrorAction SilentlyContinue | Out-Null
    $runPaths = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run")
    $whitelist = @("SecurityHealth", "WindowsDefender", "OneDrive", "RtkAudUService")
    foreach ($path in $runPaths) {
        if (Test-Path $path) {
            foreach ($prop in (Get-Item $path).Property) {
                if ($prop -notin $whitelist) { Remove-ItemProperty -Path $path -Name $prop -ErrorAction SilentlyContinue }
            }
        }
    }
    # Desactivar animaciones visuales
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Force
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "AnimateControls" -Value 0 -Force
    Write-Host "[OK] Servicios y arranque optimizados al 100%." -ForegroundColor Green
}

function Instalar-Supremo {
    Write-Host "`n[+] Descargando herramienta Supremo..." -ForegroundColor Cyan
    try {
        $userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
        Invoke-WebRequest -Uri "https://www.supremocontrol.com/download/Supremo.exe" -OutFile "$env:PUBLIC\Desktop\Supremo.exe" -UserAgent $userAgent -ErrorAction Stop
        Write-Host "[OK] Supremo listo en el Escritorio Público." -ForegroundColor Green
    } catch { Write-Warning "Fallo al bajar Supremo: $_" }
}

function Desinstalar-Todo {
    Write-Host "`n[-] Iniciando desinstalación completa..." -ForegroundColor Red
    $appsToUninstall = @("Google.Chrome", "Mozilla.Firefox", "VideoLAN.VLC", "Adobe.Acrobat.Reader.64-bit")
    foreach ($app in $appsToUninstall) {
        Write-Host "-> Eliminando $app..." -ForegroundColor Yellow
        winget uninstall --id $app --silent -ErrorAction SilentlyContinue
    }
    if (Test-Path "$env:PUBLIC\Desktop\Supremo.exe") { Remove-Item "$env:PUBLIC\Desktop\Supremo.exe" -Force }
    Write-Host "[OK] Limpieza de entorno terminada." -ForegroundColor Green
}

# ==========================================
# BUCLE PRINCIPAL DEL MENÚ
# ==========================================
do {
    Clear-Host
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "          PANEL DE CONTROL - PC SETUP        " -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host " 1) EJECUTAR INSTALACIÓN COMPLETA (Todo junto)" -ForegroundColor Green
    Write-Host " 2) Instalar SOLO Navegadores y Apps Base" -ForegroundColor White
    Write-Host " 3) Configurar SOLO Navegadores (Google.cat)" -ForegroundColor White
    Write-Host " 4) Instalar SOLO Microsoft Office 2021" -ForegroundColor White
    Write-Host " 5) Instalar SOLO Herramienta Supremo" -ForegroundColor White
    Write-Host " 6) Lanzar ACTIVACIÓN de Windows / Office (Massgrave)" -ForegroundColor Yellow
    Write-Host " 7) DESINSTALAR aplicaciones y limpiar entorno" -ForegroundColor Red
    Write-Host " 8) Salir" -ForegroundColor White
    Write-Host "=============================================" -ForegroundColor Cyan
    
    $opcion = Read-Host "Elige una opción (1-8)"

    switch ($opcion) {

            "1" {
            # Evita el error comprobando si ya hay una transcripción activa antes de iniciarla
            if ($null -eq (Get-Transcript -ErrorAction SilentlyContinue)) {
                Start-Transcript -Path "$env:TEMP\pc-setup-log.txt" -Force
            }
            
            Instalar-Navegadores
            Configurar-Navegadores
            Instalar-Office
            Optimizar-Sistema
            Instalar-Supremo
            
            # Detiene la transcripción de forma segura solo si está corriendo
            if ($null -ne (Get-Transcript -ErrorAction SilentlyContinue)) {
                Stop-Transcript
            }
            
            Write-Host "`n[OK] ¡Proceso completo finalizado con éxito!" -ForegroundColor Green
            Read-Host "`nPresiona Enter para volver al menú..."
        }
        }
        "2" { Instalar-Navegadores; Read-Host "`nPresiona Enter para volver al menú..." }
        "3" { Configurar-Navegadores; Read-Host "`nPresiona Enter para volver al menú..." }
        "4" { Instalar-Office; Read-Host "`nPresiona Enter para volver al menú..." }
        "5" { Instalar-Supremo; Read-Host "`nPresiona Enter para volver al menú..." }
        "6" { 
            Write-Host "`n[+] Lanzando script oficial de activación..." -ForegroundColor Yellow
            irm https://get.activated.win | iex
            Read-Host "`nPresiona Enter para volver al menú..." 
        }
        "7" { Desinstalar-Todo; Read-Host "`nPresiona Enter para volver al menú..." }
        "8" { Write-Host "`nSaliendo del instalador..." -ForegroundColor Gray; break }
        Default { Write-Host "`nOpción no válida, intenta de nuevo." -ForegroundColor Red; Start-Sleep -Seconds 2 }
    }
} while ($opcion -ne "8")
