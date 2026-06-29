Write-Host "Instalando apps esenciales..." -ForegroundColor Cyan

# Asegurar que winget está disponible en la sesión actual de Administrador
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Warning "Winget no se detecta en el PATH. Refrescando variables de entorno..."
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

$apps = @(
    "Google.Chrome",
    "Mozilla.Firefox",
    "VideoLAN.VLC",
    "Adobe.Acrobat.Reader.64-bit"
)

foreach ($app in $apps) {
    Write-Host "-> Instalando: $app..." -ForegroundColor Yellow
    try {
        # Executamos winget capturando posibles errores sin congelar el bucle
        winget install --id $app --silent --accept-package-agreements --accept-source-agreements --exact --override "/qn"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] $app instalado correctamente." -ForegroundColor Green
        } else {
            Write-Warning "[AVISO] $app devolvió un código de salida no esperado ($LASTEXITCODE)."
        }
    } catch {
        Write-Error "Error crítico al intentar instalar $app: $_"
    }
}
