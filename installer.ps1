function Configurar-Navegadores {
    Write-Host "`n[+] Configurando y forzando políticas de navegación (Google.cat)..." -ForegroundColor Cyan
    
    # 1. CERRAR ABSOLUTAMENTE TODOS LOS NAVEGADORES PARA DESBLOQUEAR RUTA
    Stop-Process -Name "firefox" -Force -ErrorAction SilentlyContinue
    Stop-Process -Name "chrome" -Force -ErrorAction SilentlyContinue
    Stop-Process -Name "msedge" -Force -ErrorAction SilentlyContinue
    Stop-Process -Name "setup" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    # 2. BORRAR CONFIGURACIONES PREVIAS DE USUARIO QUE INTERFIEREN
    $userPaths = Get-ChildItem "C:\Users" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    foreach ($user in $userPaths) {
        Remove-Item "C:\Users\$user\AppData\Local\Google\Chrome\User Data\Default\Preferences" -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\Default\Preferences" -Force -ErrorAction SilentlyContinue
    }

    # 3. FORZADO LOCAL MEDIANTE EL REGISTRO DE WINDOWS (CHROME Y EDGE)
    $chromePath = "HKLM:\SOFTWARE\Google\Chrome"
    $edgePath   = "HKLM:\SOFTWARE\Microsoft\Edge"
    $paths = @($chromePath, $edgePath)

    foreach ($p in $paths) {
        if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        Set-ItemProperty -Path $p -Name "HomepageLocation" -Value "https://www.google.cat" -Force
        Set-ItemProperty -Path $p -Name "RestoreOnStartup" -Value 4 -Force
        
        $urlsP = "$p\RestoreOnStartupURLs"
        if (-not (Test-Path $urlsP)) { New-Item -Path $urlsP -Force | Out-Null }
        Set-ItemProperty -Path $urlsP -Name "1" -Value "https://www.google.cat" -Force
        
        Set-ItemProperty -Path $p -Name "DefaultSearchProviderEnabled" -Value 1 -Force
        Set-ItemProperty -Path $p -Name "DefaultSearchProviderName" -Value "Google" -Force
        Set-ItemProperty -Path $p -Name "DefaultSearchProviderSearchURL" -Value "https://www.google.cat/search?q={searchTerms}" -Force
    }
    
    # 4. FORZADO DE POLÍTICA EN FIREFOX (ESTRICTO UTF-8 SIN BOM)
    $jsonContent = '{"policies":{"Homepage":{"URL":"https://www.google.cat","StartPage":"homepage","Locked":true},"SearchEngines":{"Default":"Google","PreventInstalls":true,"Remove":["Bing","Yahoo","DuckDuckGo","eBay"]}}}'
    $ffPaths = @("C:\Program Files\Mozilla Firefox", "C:\Program Files (x86)\Mozilla Firefox")
    
    # Creamos un codificador estricto UTF-8 sin BOM (Sin marca de bytes que rompa el lector de Firefox)
    $utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
    
    foreach ($ffPath in $ffPaths) {
        $ffDir = "$ffPath\distribution"
        if (-not (Test-Path $ffDir)) { New-Item -ItemType Directory -Path $ffDir -Force | Out-Null }
        
        # Guardar usando la API nativa de .NET para asegurar compatibilidad total en Win 7, 8, 10 y 11
        [System.IO.File]::WriteAllText("$ffDir\policies.json", $jsonContent, $utf8NoBOM)
    }
    
    Write-Host "[OK] Navegadores vinculados y limpiados de raíz con éxito." -ForegroundColor Green
}
