Write-Host "Instalando apps..." -ForegroundColor Cyan

$apps = @(
    "Google.Chrome",
    "Mozilla.Firefox",
    "VideoLAN.VLC",
    "Adobe.Acrobat.Reader.64-bit"
)

foreach ($app in $apps) {
    winget install --id $app --silent --accept-package-agreements --accept-source-agreements
}