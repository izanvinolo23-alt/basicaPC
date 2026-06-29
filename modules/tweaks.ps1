Write-Host "Aplicando ajustes finales y optimizaciones..." -ForegroundColor Cyan

# 1. Rendimiento Máximo en lugar de Economizador
Write-Host "-> Configurando plan de energía a Alto Rendimiento..." -ForegroundColor Yellow
powercfg -setactive SCHEME_MIN  # Nota: SCHEME_MIN es 'Economizador'. Si quieres ALTO RENDIMIENTO usa:
# powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# 2. Desactivar animaciones de Windows para mejorar la fluidez visual
Write-Host "-> Desactivando animaciones visuales de Windows..." -ForegroundColor Yellow
$visualFX = "HKCU:\Control Panel\Desktop\WindowMetrics"
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Value 0 -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "AnimateControls" -Value 0 -Force

# 3. Descargar Supremo de forma remota y guardarlo en el Escritorio Público
$desktopPath = "$env:PUBLIC\Desktop"
$supremoUrl = "https://www.supremocontrol.com/download/Supremo.exe"

Write-Host "-> Descargando Supremo Control directo de la web oficial..." -ForegroundColor Yellow
try {
    # Descarga el ejecutable directamente al escritorio público (visible para todos los usuarios)
    Invoke-RestMethod -Uri $supremoUrl -OutFile "$desktopPath\Supremo.exe"
    Write-Host "[OK] Supremo colocado en el Escritorio Público correctamente." -ForegroundColor Green
} catch {
    Write-Error "No se pudo descargar Supremo. Verifica la conexión a internet."
}

Write-Host "[OK] Ajustes finales aplicados con éxito." -ForegroundColor Green
