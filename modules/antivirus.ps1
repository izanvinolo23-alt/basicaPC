Write-Host "Instalando ESET NOD32..." -ForegroundColor Cyan

$eset = ".\ESET\eset_installer.exe"

if (Test-Path $eset) {
    Start-Process $eset -ArgumentList "--silent --accepteula" -Wait
} else {
    Write-Host "ESET no encontrado" -ForegroundColor Yellow
}