# 1. Definir la URL base apuntando EXACTAMENTE a tu carpeta de módulos (sin barra al final)
$base = "https://raw.githubusercontent.com/izanvinolo23-alt/basicaPC/main/modules"

Write-Host "Descargando módulos desde GitHub..." -ForegroundColor Yellow

# 2. Descargar y ejecutar cada módulo de forma limpia
# Usamos el operador de ruta de PowerShell (Join-Path) para evitar errores con las barras de las URLs
Invoke-Expression (Invoke-RestMethod -Uri "$base/apps.ps1")
Invoke-Expression (Invoke-RestMethod -Uri "$base/browsers.ps1")
Invoke-Expression (Invoke-RestMethod -Uri "$base/windows.ps1")
Invoke-Expression (Invoke-RestMethod -Uri "$base/office.ps1")
Invoke-Expression (Invoke-RestMethod -Uri "$base/tweaks.ps1")
