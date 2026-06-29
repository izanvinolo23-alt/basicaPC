Write-Host "Optimizando servicios del sistema..." -ForegroundColor Cyan

# Lista ampliada de servicios innecesarios (Telemetría, Xbox, Reportes de error, Mapas)
$services = @(
    "DiagTrack",       # Telemetría y experiencias de usuario conectadas
    "dmwappushservice", # Servicio de enrutamiento de mensajes de inserción de WAP (Rastreo)
    "XblGameSave",     # Guardado de juegos de Xbox
    "XblAuthManager",   # Administrador de autenticación de Xbox
    "XboxNetApiSvc",   # Servicio de red de Xbox Live
    "XboxGipSvc",      # Accesorio de Xbox
    "WSearch",         # Windows Search (Indexación, opcional pero consume recursos)
    "WerSvc",          # Servicio de informe de errores de Windows
    "MapsBroker",      # Administrador de mapas descargados
    "ParentalControls" # Controles parentales
)

# Lista de palabras clave de seguridad que NUNCA debemos tocar (Seguridad y Antivirus)
$protegidos = @("WinDefend", "Sense", "WdNisSvc", "SecurityHealthService")

foreach ($s in $services) {
    # Doble verificación: que exista y que no esté en la lista de protegidos por seguridad
    if ((Get-Service $s -ErrorAction SilentlyContinue) -and ($s -notin $protegidos)) {
        Write-Host "-> Deshabilitando: $s..." -ForegroundColor Yellow
        
        # 1. Detener el servicio en ejecución si es posible
        Stop-Service $s -Force -ErrorAction SilentlyContinue
        
        # 2. Modificar el registro para asegurar que quede deshabilitado (Start = 4)
        # Esto evita bloqueos de permisos que a veces tiene 'Set-Service' con telemetría
        reg.exe add "HKLM\SYSTEM\CurrentControlSet\Services\$s" /v Start /t REG_DWORD /d 4 /f | Out-Null
    }
}

Write-Host "[OK] Servicios optimizados. Windows Defender permanece activo." -ForegroundColor Green
