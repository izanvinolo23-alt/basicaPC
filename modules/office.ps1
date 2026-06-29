Write-Host "Iniciando instalación automatizada de Microsoft Office..." -ForegroundColor Cyan

# 1. Crear directorio temporal de trabajo
$tempDir = "$env:TEMP\OfficeSetup"
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }

$setupExe = "$tempDir\setup.exe"
$configFile = "$tempDir\configuration.xml"

# 2. Descargar el Office Deployment Tool (ODT) oficial de Microsoft
# Enlace directo permanente al instalador de Microsoft
$odtUrl = "https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB029D4A9D/officedeploymenttool_17628-20164.exe"
Write-Host "Descargando Office Deployment Tool..." -ForegroundColor Yellow
Invoke-RestMethod -Uri $odtUrl -OutFile "$tempDir\odt.exe"

# Extraer el setup.exe de forma silenciosa del empaquetado oficial
Start-Process -FilePath "$tempDir\odt.exe" -ArgumentList "/extract:`"$tempDir`" /quiet" -Wait

# 3. Descargar TU archivo de configuración personalizado desde tu GitHub
# Asegúrate de crear este archivo en tu repositorio dentro de la carpeta 'modules' u 'office'
$githubConfigUrl = "https://raw.githubusercontent.com/izanvinolo23-alt/basicaPC/main/modules/configuration.xml"
Write-Host "Descargando tu configuración personalizada de Office..." -ForegroundColor Yellow
Invoke-RestMethod -Uri $githubConfigUrl -OutFile $configFile

# 4. Lanzar la instalación oficial descargando los archivos en tiempo real
if (Test-Path $setupExe) {
    Write-Host "Instalando Office de forma silenciosa (esto puede tardar varios minutos)..." -ForegroundColor Magenta
    # /configure descarga e instala directamente usando los parámetros de tu XML
    $process = Start-Process -FilePath $setupExe -ArgumentList "/configure `"$configFile`"" -Wait -NoNewWindow -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "[OK] Microsoft Office instalado correctamente." -ForegroundColor Green
    } else {
        Write-Error "Error en la instalación de Office. Código de salida: $($process.ExitCode)"
    }
} else {
    Write-Host "Error crítico: No se pudo extraer setup.exe" -ForegroundColor Red
}

# 5. Limpieza de archivos temporales
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
