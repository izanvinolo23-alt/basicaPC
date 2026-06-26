Write-Host "Instalando Office..." -ForegroundColor Cyan

$setup = ".\Office\setup.exe"

if (Test-Path $setup) {
    Start-Process $setup -ArgumentList "/configure configuration.xml" -Wait
} else {
    Write-Host "Office no encontrado" -ForegroundColor Yellow
}