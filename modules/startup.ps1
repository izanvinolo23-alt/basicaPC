Write-Host "Configurando inicio..." -ForegroundColor Cyan

$run = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"

# limpiar inicio
Get-ItemProperty $run -ErrorAction SilentlyContinue | ForEach-Object {
    $_.PSObject.Properties | ForEach-Object {
        Remove-ItemProperty $run -Name $_.Name -ErrorAction SilentlyContinue
    }
}

# solo lo que tú quieras
Set-ItemProperty $run "MiPrograma" "C:\Ruta\MiPrograma.exe"