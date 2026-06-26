Write-Host "Optimizando servicios..." -ForegroundColor Cyan

$services = @(
    "DiagTrack",
    "XblGameSave",
    "WSearch"
)

foreach ($s in $services) {
    if (Get-Service $s -ErrorAction SilentlyContinue) {
        Stop-Service $s -Force -ErrorAction SilentlyContinue
        Set-Service $s -StartupType Disabled
    }
}