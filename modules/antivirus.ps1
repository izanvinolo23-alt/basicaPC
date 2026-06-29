Write-Host "Iniciando instalación automatizada de ESET NOD32 Antivirus..." -ForegroundColor Cyan

# 1. Crear directorio temporal de trabajo
$tempDir = "$env:TEMP\ESETSetup"
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }

$esetExe = "$tempDir\eset_installer.exe"

# 2. Enlace oficial del instalador de ESET (Live Installer para España/Europa)
$esetUrl = "https://download.eset.com/com/eset/apps/home/eav/windows/latest/eset_nod32_antivirus_live_installer.exe"

Write-Host "-> Descargando ESET Live Installer desde los servidores oficiales..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri $esetUrl -OutFile $esetExe
} catch {
    Write-Error "Error al descargar el instalador de ESET. Comprueba la conexión."
    return
}

# 3. Ejecución de la instalación silenciosa
if (Test-Path $esetExe) {
    Write-Host "-> Instalando ESET NOD32 en segundo plano (esto puede tomar un momento)..." -ForegroundColor Magenta
    
    # Parámetros estándar de ESET para instaladores MSI/Live desatendidos
    # /qn fuerza el modo silencioso de Windows Installer. /silent oculta la interfaz.
    $process = Start-Process -FilePath $esetExe -ArgumentList "/silent /qn /norestart" -Wait -NoNewWindow -PassThru

    if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
        if ($process.ExitCode -eq 3010) {
            Write-Host "[OK] ESET instalado correctamente. Requiere reiniciar el sistema." -ForegroundColor Yellow
        } else {
            Write-Host "[OK] ESET NOD32 Antivirus se ha instalado con éxito." -ForegroundColor Green
        }
    } else {
        Write-Warning "[AVISO] La instalación terminó con un código de salida no esperado: $($process.ExitCode)"
    }
} else {
    Write-Error "No se encontró el instalador descargado en la ruta temporal."
}

# 4. Limpieza del instalador temporal
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
