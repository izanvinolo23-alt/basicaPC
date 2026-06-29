# ==============================================================================
# PC SETUP UNIFICADO - MENÚ INTERACTIVO PROFESIONAL
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

# Funciones de soporte para mantener el código limpio
function Instalar-Navegadores {
    Write-Host "`n[+] Instalando Google Chrome y Mozilla Firefox..." -ForegroundColor Cyan
    winget source update --accept-source-agreements | Out-Null
    $browsers = @("Google.Chrome", "Mozilla.Firefox")
    foreach ($b in $browsers) {
        Write-Host "-> Instalando: $b..." -ForegroundColor Yellow
        if ($b -eq "Mozilla.Firefox") {
            winget install --id $b --silent --accept-package-agreements --accept-source-agreements --exact --override "/S"
        } else {
            winget install --id $b --silent --accept-package-agreements --accept-source-agreements --exact
        }
    }
    Write-Host "[OK] Navegadores instalados." -ForegroundColor Green
}

function Configurar-Navegadores {
    Write-Host "`n[+] Configurando políticas (Google.cat)..." -ForegroundColor Cyan
    $paths = @("HKLM:\SOFTWARE\Policies\Microsoft\Edge", "HKLM:\SOFTWARE\Policies\Google\Chrome")
    foreach ($p in $paths) {
        if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        Set-ItemProperty -Path $p -Name "HomepageLocation" -Value "https://www.google.cat" -Force
        Set-ItemProperty -Path $p -Name "RestoreOnStartup" -Value 4 -Force
        $urlsP = "$p\RestoreOnStartupURLs"
        if (-not (Test-Path $urlsP)) { New-Item -Path $urlsP -Force | Out-Null }
        Set-ItemProperty -Path $urlsP -Name "1" -Value "https://www.google.cat" -Force
    }
    $ffDir = "C:\Program Files\Mozilla Firefox\distribution"
    if (-not (Test-Path $ffDir)) { New-Item -ItemType Directory -Path $ffDir -Force | Out-Null }
    '{"policies":{"Homepage":{"URL":"https://www.google.cat","StartPage":"homepage","Locked":true}}}' | Out-File -FilePath "$ffDir\policies.json" -Encoding utf8 -Force
    Write-Host "[OK] Políticas aplicadas a Google.cat." -ForegroundColor Green
}

function Instalar-Office {
    Write-Host "`n[+] Iniciando instalación automatizada de Microsoft Office..." -ForegroundColor Cyan
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
        Write-Host "[OK] Microsoft Office instalado." -ForegroundColor Green
    } catch { Write-Error "Fallo en Office: $_" }
}

function Instalar-Supremo {
    Write-Host "`n[+] Descargando Supremo..." -ForegroundColor Cyan
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
    Write-Host "[OK] Limpieza terminada." -ForegroundColor Green
}

# ==========================================
# BUCLE PRINCIPAL DEL MENÚ
# ==========================================
do {
    Clear-Host
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "          PANEL DE CONTROL - PC SETUP        " -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host " 1) Instalar SOLO Navegadores (Chrome/Firefox)" -ForegroundColor White
    Write-Host " 2) Configurar SOLO Navegadores (Google.cat)" -ForegroundColor White
    Write-Host " 3) Instalar SOLO Microsoft Office 2021" -ForegroundColor White
    Write-Host " 4) Instalar SOLO Herramienta Supremo" -ForegroundColor White
    Write-Host " 5) Lanzar ACTIVACIÓN de Windows / Office (Massgrave)" -ForegroundColor Yellow
    Write-Host " 6) Ejecutar INSTALACIÓN COMPLETA (Todo el catálogo)" -ForegroundColor Green
    Write-Host " 7) DESINSTALAR aplicaciones y limpiar entorno" -ForegroundColor Red
    Write-Host " 8) Salir" -ForegroundColor White
    Write-Host "=============================================" -ForegroundColor Cyan
    
    $opcion = Read-Host "Elige una opción (1-8)"

    switch ($opcion) {
        "1" { Instalar-Navegadores; Read-Host "`nPresiona Enter para volver al menú..." }
        "2" { Configurar-Navegadores; Read-Host "`nPresiona Enter para volver al menú..." }
        "3" { Instalar-Office; Read-Host "`nPresiona Enter para volver al menú..." }
        "4" { Instalar-Supremo; Read-Host "`nPresiona Enter para volver al menú..." }
        "5" { 
            Write-Host "`n[+] Lanzando script oficial de activación..." -ForegroundColor Yellow
            irm https://get.activated.win | iex
            Read-Host "`nPresiona Enter para volver al menú..." 
        }
        "6" {
            Start-Transcript -Path "$env:TEMP\pc-setup-log.txt"
            Instalar-Navegadores
            Configurar-Navegadores
            Instalar-Office
            Instalar-Supremo
            # Resto de optimizaciones automáticas
            Write-Host "`n[+] Aplicando optimizaciones del sistema..." -ForegroundColor Cyan
            $services = @("DiagTrack", "dmwappushservice", "XblGameSave", "XblAuthManager", "WSearch", "WerSvc")
            foreach ($s in $services) { if (Get-Service $s -ErrorAction SilentlyContinue) { Stop-Service $s -Force; reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\$s" /v Start /t REG_DWORD /d 4 /f | Out-Null } }
            Stop-Transcript
            Write-Host "`n[OK] Instalación completa finalizada con éxito." -ForegroundColor Green
            Read-Host "`nPresiona Enter para volver al menú..."
        }
        "7" { Desinstalar-Todo; Read-Host "`nPresiona Enter para volver al menú..." }
        "8" { Write-Host "`nSaliendo del instalador..." -ForegroundColor Gray; break }
        Default { Write-Host "`nOpción no válida, intenta de nuevo." -ForegroundColor Red; Start-Sleep -Seconds 2 }
    }
} while ($opcion -ne "8")
