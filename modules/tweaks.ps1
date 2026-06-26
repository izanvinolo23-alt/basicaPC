Write-Host "Aplicando ajustes finales..." -ForegroundColor Cyan

# Quitar animaciones
powercfg -setactive SCHEME_MIN

# Copiar Supremo
Copy-Item ".\Supremo.exe" "$env:PUBLIC\Desktop\Supremo.exe" -Force