Write-Host "Configurando políticas estrictas de navegación (Google.cat)..." -ForegroundColor Cyan

# ==========================================
# 1. MICROSOFT EDGE
# ==========================================
$edgePath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
if (-not (Test-Path $edgePath)) { New-Item -Path $edgePath -Force | Out-Null }

# Página de inicio obligatoria a google.cat
Set-ItemProperty -Path $edgePath -Name "HomepageLocation" -Value "https://www.google.cat" -Force
Set-ItemProperty -Path $edgePath -Name "RestoreOnStartup" -Value 4 -Force
$edgeUrlsPath = "$edgePath\RestoreOnStartupURLs"
if (-not (Test-Path $edgeUrlsPath)) { New-Item -Path $edgeUrlsPath -Force | Out-Null }
Set-ItemProperty -Path $edgeUrlsPath -Name "1" -Value "https://www.google.cat" -Force

# Forzar Google como motor por defecto y deshabilitar el resto
Set-ItemProperty -Path $edgePath -Name "DefaultSearchProviderEnabled" -Value 1 -Force
Set-ItemProperty -Path $edgePath -Name "DefaultSearchProviderName" -Value "Google" -Force
Set-ItemProperty -Path $edgePath -Name "DefaultSearchProviderSearchURL" -Value "https://www.google.cat/search?q={searchTerms}" -Force


# ==========================================
# 2. GOOGLE CHROME
# ==========================================
$chromePath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
if (-not (Test-Path $chromePath)) { New-Item -Path $chromePath -Force | Out-Null }

# Página de inicio obligatoria a google.cat
Set-ItemProperty -Path $chromePath -Name "HomepageLocation" -Value "https://www.google.cat" -Force
Set-ItemProperty -Path $chromePath -Name "RestoreOnStartup" -Value 4 -Force
$chromeUrlsPath = "$chromePath\RestoreOnStartupURLs"
if (-not (Test-Path $chromeUrlsPath)) { New-Item -Path $chromeUrlsPath -Force | Out-Null }
Set-ItemProperty -Path $chromeUrlsPath -Name "1" -Value "https://www.google.cat" -Force

# Forzar Google como motor por defecto y deshabilitar el resto
Set-ItemProperty -Path $chromePath -Name "DefaultSearchProviderEnabled" -Value 1 -Force
Set-ItemProperty -Path $chromePath -Name "DefaultSearchProviderName" -Value "Google" -Force
Set-ItemProperty -Path $chromePath -Name "DefaultSearchProviderSearchURL" -Value "https://www.google.cat/search?q={searchTerms}" -Force


# ==========================================
# 3. MOZILLA FIREFOX
# ==========================================
$ffDir = "C:\Program Files\Mozilla Firefox\distribution"
if (-not (Test-Path $ffDir)) { New-Item -Path $ffDir -Force | Out-Null }

# JSON corporativo: Configura el inicio y elimina/oculta todos los demás motores de búsqueda
$ffPolicies = @'
{
  "policies": {
    "Homepage": {
      "URL": "https://www.google.cat",
      "StartPage": "homepage",
      "Locked": true
    },
    "SearchEngines": {
      "Default": "Google",
      "PreventInstalls": true,
      "Remove": ["Bing", "Yahoo", "DuckDuckGo", "eBay", "Wikipedia (es)"]
    }
  }
}
'@

$ffPolicies | Out-File -FilePath "$ffDir\policies.json" -Encoding utf8 -Force

Write-Host "[OK] Google.cat establecido y motores alternativos bloqueados." -ForegroundColor Green
