function Configurar-Navegadores {
    Write-Host "`n[+] Configurando y forzando políticas de navegación (Google.cat)..." -ForegroundColor Cyan
    
    # 1. CERRAR PROCESOS Y SERVICIOS EN SEGUNDO PLANO DE LOS NAVEGADORES
    $procs = @("firefox", "chrome", "msedge", "setup", "GoogleUpdate", "MicrosoftEdgeUpdate")
    foreach ($p in $procs) {
        Stop-Process -Name $p -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 2

    # 2. BORRAR PREFERENCIAS PREVIAS DE LOS USUARIOS
    $userPaths = Get-ChildItem "C:\Users" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    foreach ($user in $userPaths) {
        Remove-Item "C:\Users\$user\AppData\Local\Google\Chrome\User Data\Default\Preferences" -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\Default\Preferences" -Force -ErrorAction SilentlyContinue
    }

    # 3. DOBLE INYECCIÓN EN EL REGISTRO (RUTAS LOCALES Y RUTAS DE POLÍTICAS)
    # Esto asegura que funcione tanto si el PC está en grupo de trabajo como en dominio
    $registryPaths = @(
        "HKLM:\SOFTWARE\Google\Chrome",
        "HKLM:\SOFTWARE\Policies\Google\Chrome",
        "HKLM:\SOFTWARE\Microsoft\Edge",
        "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    )

    foreach ($p in $registryPaths) {
        if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        
        # Fijar la página de inicio al arrancar
        Set-ItemProperty -Path $p -Name "HomepageLocation" -Value "https://www.google.cat" -Force
        Set-ItemProperty -Path $p -Name "RestoreOnStartup" -Value 4 -Force
        
        # Forzar la pestaña de Google.cat
        $urlsP = "$p\RestoreOnStartupURLs"
        if (-not (Test-Path $urlsP)) { New-Item -Path $urlsP -Force | Out-Null }
        Set-ItemProperty -Path $urlsP -Name "1" -Value "https://www.google.cat" -Force
        
        # Bloquear el motor de búsqueda a Google
        Set-ItemProperty -Path $p -Name "DefaultSearchProviderEnabled" -Value 1 -Force
        Set-ItemProperty -Path $p -Name "DefaultSearchProviderName" -Value "Google" -Force
        Set-ItemProperty -Path $p -Name "DefaultSearchProviderSearchURL" -Value "https://www.google.cat/search?q={searchTerms}" -Force
    }
    
    # 4. FORZADO DE POLÍTICA EN FIREFOX (ESTRICTO UTF-8 SIN BOM)
    $jsonContent = '{"policies":{"Homepage":{"URL":"https://www.google.cat","StartPage":"homepage","Locked":true},"SearchEngines":{"Default":"Google","PreventInstalls":true,"Remove":["Bing","Yahoo","DuckDuckGo","eBay"]}}}'
    $ffPaths = @("C:\Program Files\Mozilla Firefox", "C:\Program Files (x86)\Mozilla Firefox")
    $utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
    
    foreach ($ffPath in $ffPaths) {
        $ffDir = "$ffPath\distribution"
        if (-not (Test-Path $ffDir)) { New-Item -ItemType Directory -Path $ffDir -Force | Out-Null }
        [System.IO.File]::WriteAllText("$ffDir\policies.json", $jsonContent, $utf8NoBOM)
    }
    
    # 5. OBLIGAR A WINDOWS A REFRESCAR LAS DIRECTIVAS DE GRUPO AL INSTANTE
    Write-Host "-> Aplicando cambios en las directivas del sistema operativo..." -ForegroundColor Yellow
    gpupdate /force | Out-Null
    
    Write-Host "[OK] Navegadores vinculados, limpiados y políticas aplicadas con gpupdate." -ForegroundColor Green
