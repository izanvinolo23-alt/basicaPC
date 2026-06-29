Write-Host "Maximizando rendimiento de arranque y limpiando software..." -ForegroundColor Cyan

# 1. ACLARACIÓN TÉCNICA: Dejar que Windows gestione los núcleos automáticamente garantiza el uso del 100% de la CPU.
# Forzar 'numproc' por comandos suele limitar el rendimiento o causar pantallazos azules.
Write-Host "-> Optimizando el uso nativo de CPU (Garantizando el uso de todos los núcleos)..." -ForegroundColor Yellow
bcdedit /deletevalue {current} numproc ErrorAction SilentlyContinue | Out-Null
bcdedit /deletevalue {current} truncatememory ErrorAction SilentlyContinue | Out-Null

# 2. Rutas de inicio en el registro (Usuario actual y Máquina local)
$runPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
)

# Lista de procesos legítimos y críticos que NUNCA debemos borrar del inicio
$whitelist = @("SecurityHealth", "WindowsDefender", "OneDrive", "RtkAudUService")

foreach ($path in $runPaths) {
    if (Test-Path $path) {
        Write-Host "Limpiando ejecutables innecesarios en: $path" -ForegroundColor Yellow
        
        # Obtenemos todas las propiedades de la clave de registro
        $properties = (Get-Item $path).Property
        
        foreach ($prop in $properties) {
            # Si el programa no está en la lista blanca, se elimina del arranque
            if ($prop -notin $whitelist) {
                Remove-ItemProperty -Path $path -Name $prop -ErrorAction SilentlyContinue
                Write-Host "   [X] Eliminado del inicio: $prop" -ForegroundColor DarkGray
            }
        }
    }
}

# 3. Añadir tus programas personalizados de forma segura si lo requieres
# $myRun = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
# Set-ItemProperty -Path $myRun -Name "MiPrograma" -Value "C:\Ruta\MiPrograma.exe" -Force

Write-Host "[OK] Arranque limpio. El procesador gestionará todos sus núcleos nativamente." -ForegroundColor Green
