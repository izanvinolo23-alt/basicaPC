# ==============================================================================
# GESTOR DE DESPLIEGUE MULTIVERSIÓN - SCRIPT FINAL COMPLETADO
# ==============================================================================

# 1. FORZAR ADMINISTRADOR
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Reejecutando con privilegios de Administrador..."
    $remoteCommand = "irm https://raw.githubusercontent.com/izanvinolo23-alt/basicaPC/main/installer.ps1 | iex"
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$remoteCommand`"" -Verb RunAs
    Exit
}

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# SOPORTE TLS 1.2 INTEGRAL (Vital para descargas en Windows 7)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

$Global:TranscripcionActiva = $false
$userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"

# ==============================================================================
# FUNCIONES: SISTEMAS MODERNOS (WINDOWS 10 / 11)
# ==============================================================================
function Instalar-Apps-Modernas {
    Write-Host "`n[+] Instalando aplicaciones esenciales mediante Winget..." -ForegroundColor Cyan
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
        } catch { Write-Error "Error al intentar instalar $app : $_" }
    }
}

function Instalar-Office-Moderno {
    Write-Host "`n[+] Iniciando instalación automatizada de Microsoft Office 2019..." -ForegroundColor Cyan
    $officeTemp = "$env:TEMP\OfficeSetup"
    if (-not (Test-Path $officeTemp)) { New-Item -ItemType Directory -Path $officeTemp -Force | Out-Null }
    try {
        Write-Host "-> Descargando Office Deployment Tool desde el servidor oficial..." -ForegroundColor Yellow
        $odtUrl = "https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB029D4A9D/officedeploymenttool_18230-20046.exe"
        Invoke-WebRequest -Uri $odtUrl -OutFile "$officeTemp\odt.exe" -UserAgent $Global:userAgent -ErrorAction Stop

        Write-Host "-> Extrayendo archivos de configuración..." -ForegroundColor Yellow
        Start-Process -FilePath "$officeTemp\odt.exe" -ArgumentList "/extract:`"$officeTemp`" /quiet" -Wait

        $xmlContent = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="PerpetualVL2019">
    <Product ID="ProPlus2019Volume">
      <Language ID="es-es" />
      <ExcludeApp ID="Lync" />
      <ExcludeApp ID="OneDrive" />
      <ExcludeApp ID="OneNote" />
    </Product>
  </Add>
  <Display Level="None" AcceptEULA="TRUE" />
  <Property Name="AUTOACTIVATE" Value="1" />
</Configuration>
"@
        $xmlContent | Out-File -FilePath "$officeTemp\configuration.xml" -Encoding utf8 -Force
        
        Write-Host "-> Descargando e instalando Office 2019 en segundo plano (Tardará unos minutos)..." -ForegroundColor Yellow
        $setupProcess = Start-Process -FilePath "$officeTemp\setup.exe" -ArgumentList "/configure `"$officeTemp\configuration.xml`"" -Wait -PassThru
        
        if ($setupProcess.ExitCode -eq 0) {
            Write-Host "[OK] Microsoft Office 2019 instalado correctamente." -ForegroundColor Green
        } else {
            Write-Warning "El instalador de Office cerró con el código de error: $($setupProcess.ExitCode)"
        }
    } catch { 
        Write-Error "Fallo crítico en la instalación desatendida de Office 2019: $_" 
    }
}

# ==============================================================================
# FUNCIONES: SISTEMAS ANTIGUOS (WINDOWS 7 / 8 / 8.1)
# ==============================================================================
function Instalar-Apps-Antiguas {
    Write-Host "`n[+] Descargando e Instalando Apps de forma Directa (Sin Winget)..." -ForegroundColor Cyan
    $tempDir = "$env:TEMP\LegacyApps"
    if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }

    $downloads = @{
        "Chrome"  = @("https://dl.google.com/chrome/install/standalonesetup64.exe", "$tempDir\chrome_setup.exe", "/silent /install")
        "Firefox" = @("https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=es-ES", "$tempDir\firefox_setup.exe", "-ms")
        "VLC"     = @("https://get.videolan.org/vlc/last/win64/vlc-3.0.21-win64.exe", "$tempDir\vlc_setup.exe", "/S")
    }

    foreach ($app in $downloads.Keys) {
        Write-Host "-> Descargando $app de la web oficial..." -ForegroundColor Yellow
        try {
            Invoke-WebRequest -Uri $downloads[$app][0] -OutFile $downloads[$app][1] -UserAgent $Global:userAgent -ErrorAction Stop
            Write-Host "-> Instalando $app en segundo plano..." -ForegroundColor Yellow
            Start-Process -FilePath $downloads[$app][1] -ArgumentList $downloads[$app][2] -Wait
            Write-Host "[OK] $app instalado correctamente." -ForegroundColor Green
        } catch { Write-Error "No se pudo procesar $app : $_" }
    }
}

function Instalar-Office-Antiguo {
    Write-Host "`n[+] Instalando de forma silenciosa Microsoft Office 2013 ProPlus..." -ForegroundColor Cyan
    $legacyOfficeDir = "$env:TEMP\LegacyOffice"
    if (-not (Test-Path $legacyOfficeDir)) { New-Item -ItemType Directory -Path $legacyOfficeDir -Force | Out-Null }
    
    try {
        Write-Host "-> Descargando paquete oficial de despliegue corporativo Office 2013..." -ForegroundColor Yellow
        $odtUrl = "https://download.microsoft.com/download/B/0/F/B0F20C39-50E8-4903-8B31-7DE016EBE35C/officedeploymenttool_x86_4731-1007.exe"
        Invoke-WebRequest -Uri $odtUrl -OutFile "$legacyOfficeDir\odt13.exe" -UserAgent $Global:userAgent -ErrorAction Stop
        
        Start-Process -FilePath "$legacyOfficeDir\odt13.exe" -ArgumentList "/extract:`"$legacyOfficeDir`" /quiet" -Wait
        
        $xmlContent = '@
<Configuration>
  <Add OfficeClientEdition="32" Channel="Volume">
    <Product ID="ProPlusVolume">
      <Language ID="es-es" />
    </Product>
  </Add>
  <Display Level="None" AcceptEULA="TRUE" />
</Configuration>
@'
        $xmlContent | Out-File -FilePath "$legacyOfficeDir\configuration.xml" -Encoding utf8 -Force
        
        Write-Host "-> Descargando e instalando los archivos base en silencio (Espera unos minutos)..." -ForegroundColor Yellow
        Start-Process -FilePath "$legacyOfficeDir\setup.exe" -ArgumentList "/configure `"$legacyOfficeDir\configuration.xml`"" -Wait
        Write-Host "[OK] Microsoft Office 2013 instalado con éxito." -ForegroundColor Green
    } catch {
        Write-Error "No se pudo realizar la instalación desatendida de Office antiguo: $_"
    }
}

# ==============================================================================
# FUNCIONES UNIVERSALES (COMPATIBLES CON TODOS LOS WINDOWS)
# ==============================================================================
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

function Optimizar-Sistema {
    Write-Host "`n[+] Aplicando optimizaciones de rendimiento generales..." -ForegroundColor Cyan
    $services = @("DiagTrack", "dmwappushservice", "XblGameSave", "XblAuthManager", "XboxNetApiSvc", "XboxGipSvc", "WSearch", "WerSvc", "MapsBroker", "ParentalControls")
    foreach ($s in $services) {
        if (Get-Service $s -ErrorAction SilentlyContinue) {
            Stop-Service $s -Force -ErrorAction SilentlyContinue
            reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\$s" /v Start /t REG_DWORD /d 4 /f | Out-Null
        }
    }
    $runPaths = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run")
    $whitelist = @("SecurityHealth", "WindowsDefender", "OneDrive", "RtkAudUService")
    foreach ($path in $runPaths) {
        if (Test-Path $path) {
            foreach ($prop in (Get-Item $path).Property) {
                if ($prop -notin $whitelist) { Remove-ItemProperty -Path $path -Name $prop -ErrorAction SilentlyContinue }
            }
        }
    }
    Write-Host "[OK] Servicios y elementos de inicio optimizados." -ForegroundColor Green
}

function Instalar-Supremo {
    Write-Host "`n[+] Descargando herramienta Supremo al Escritorio..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri "https://www.supremocontrol.com/download/Supremo.exe" -OutFile "$env:PUBLIC\Desktop\Supremo.exe" -UserAgent $Global:userAgent -ErrorAction Stop
        Write-Host "[OK] Supremo listo." -ForegroundColor Green
    } catch { Write-Warning "Fallo al bajar Supremo: $_" }
}

function Desinstalar-Todo {
    Write-Host "`n[-] Eliminando aplicaciones instaladas..." -ForegroundColor Red
    $appsToUninstall = @("Google.Chrome", "Mozilla.Firefox", "VideoLAN.VLC", "Adobe.Acrobat.Reader.64-bit")
    foreach ($app in $appsToUninstall) {
        winget uninstall --id $app --silent -ErrorAction SilentlyContinue
    }
    if (Test-Path "$env:PUBLIC\Desktop\Supremo.exe") { Remove-Item "$env:PUBLIC\Desktop\Supremo.exe" -Force }
    Write-Host "[OK] Entorno restaurado." -ForegroundColor Green
}

# ==============================================================================
# MENÚS INTERACTIVOS
# ==============================================================================
function Menu-Moderno {
    do {
        Clear-Host
        Write-Host "=============================================" -ForegroundColor Cyan
        Write-Host "       HERRAMIENTAS WINDOWS 10 / 11          " -ForegroundColor Cyan
        Write-Host "=============================================" -ForegroundColor Cyan
        Write-Host " 1) INSTALACIÓN COMPLETA (Todo junto)" -ForegroundColor Green
        Write-Host " 2) Instalar SOLO Navegadores y Apps Base (Winget)" -ForegroundColor White
        Write-Host " 3) Configurar SOLO Navegadores (Google.cat)" -ForegroundColor White
        Write-Host " 4) Instalar SOLO Microsoft Office 2019" -ForegroundColor White
        Write-Host " 5) Instalar SOLO Herramienta Supremo" -ForegroundColor White
        Write-Host " 6) Lanzar ACTIVACIÓN General (Massgrave)" -ForegroundColor Yellow
        Write-Host " 7) DESINSTALAR aplicaciones y limpiar" -ForegroundColor Red
        Write-Host " 8) <- Volver al Menú Principal" -ForegroundColor Gray
        Write-Host "=============================================" -ForegroundColor Cyan
        $opc = Read-Host "Elige una opción (1-8)"
        switch ($opc) {
            "1" {
                if (-not $Global:TranscripcionActiva) { Start-Transcript -Path "$env:TEMP\pc-setup-log.txt" -Force | Out-Null; $Global:TranscripcionActiva = $true }
                Instalar-Apps-Modernas; Configurar-Navegadores; Instalar-Office-Moderno; Optimizar-Sistema; Instalar-Supremo
                if ($Global:TranscripcionActiva) { Stop-Transcript | Out-Null; $Global:TranscripcionActiva = $false }
                Read-Host "`n[OK] Todo listo. Presiona Enter..."
            }
            "2" { Instalar-Apps-Modernas; Read-Host "`nPresiona Enter..." }
            "3" { Configurar-Navegadores; Read-Host "`nPresiona Enter..." }
            "4" { Instalar-Office-Moderno; Read-Host "`nPresiona Enter..." }
            "5" { Instalar-Supremo; Read-Host "`nPresiona Enter..." }
            "6" { Write-Host "`n[+] Lanzando Massgrave..."; irm https://get.activated.win | iex; Read-Host "`nPresiona Enter..." }
            "7" { Desinstalar-Todo; Read-Host "`nPresiona Enter..." }
            "8" { break }
        }
    } while ($opc -ne "8")
}

function Menu-Antiguo {
    do {
        Clear-Host
        Write-Host "=============================================" -ForegroundColor Yellow
        Write-Host "     HERRAMIENTAS WINDOWS 7 / 8 / 8.1        " -ForegroundColor Yellow
        Write-Host "=============================================" -ForegroundColor Yellow
        Write-Host " 1) INSTALACIÓN COMPLETA LEGACY (Todo junto)" -ForegroundColor Green
        Write-Host " 2) Instalar SOLO Navegadores (Descarga Directa Web)" -ForegroundColor White
        Write-Host " 3) Configurar SOLO Navegadores (Google.cat)" -ForegroundColor White
        Write-Host " 4) Instalar SOLO Microsoft Office Antiguo (2013)" -ForegroundColor White
        Write-Host " 5) Instalar SOLO Herramienta Supremo" -ForegroundColor White
        Write-Host " 6) Optimizar SOLO Servicios y Arranque Antiguo" -ForegroundColor White
        Write-Host " 7) Lanzar ACTIVACIÓN General (Massgrave)" -ForegroundColor Yellow
        Write-Host " 8) <- Volver al Menú Principal" -ForegroundColor Gray
        Write-Host "=============================================" -ForegroundColor Yellow
        $opc = Read-Host "Elige una opción (1-8)"
        switch ($opc) {
            "1" {
                Instalar-Apps-Antiguas; Configurar-Navegadores; Instalar-Office-Antiguo; Optimizar-Sistema; Instalar-Supremo
                Read-Host "`n[OK] Maquetación antigua finalizada. Presiona Enter..."
            }
            "2" { Instalar-Apps-Antiguas; Read-Host "`nPresiona Enter..." }
            "3" { Configurar-Navegadores; Read-Host "`nPresiona Enter..." }
            "4" { Instalar-Office-Antiguo; Read-Host "`nPresiona Enter..." }
            "5" { Instalar-Supremo; Read-Host "`nPresiona Enter..." }
            "6" { Optimizar-Sistema; Read-Host "`nPresiona Enter..." }
            "7" { Write-Host "`n[+] Lanzando Massgrave..."; irm https://get.activated.win | iex; Read-Host "`nPresiona Enter..." }
            "8" { break }
        }
    } while ($opc -ne "8")
}

# ==============================================================================
# BUCLE DEL MENÚ PRINCIPAL
# ==============================================================================
do {
    Clear-Host
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "          GESTOR DE DESPLIEGUE I.V.          " -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host " 1) Trabajar con WINDOWS 10 / 11 (Moderno)" -ForegroundColor White
    Write-Host " 2) Trabajar con WINDOWS 7 / 8 / 8.1 (Legacy)" -ForegroundColor Yellow
    Write-Host " 3) Salir" -ForegroundColor Red
    Write-Host "=============================================" -ForegroundColor Cyan
    $mainOpc = Read-Host "Selecciona el entorno del equipo (1-3)"

    switch ($mainOpc) {
        "1" { Menu-Moderno }
        "2" { Menu-Antiguo }
        "3" { Write-Host "`nCerrando el instalador..." -ForegroundColor Gray; break }
        Default { Write-Host "`nOpción incorrecta." -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
} while ($mainOpc -ne "3")
