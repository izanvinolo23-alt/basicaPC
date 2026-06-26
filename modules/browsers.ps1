Write-Host "Configurando navegadores..." -ForegroundColor Cyan

# EDGE
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Force | Out-Null
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "HomepageLocation" "https://www.google.com"
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "RestoreOnStartup" 4

# CHROME
New-Item -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Force | Out-Null
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Google\Chrome" "HomepageLocation" "https://www.google.com"
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Google\Chrome" "RestoreOnStartup" 4

# FIREFOX
$ff = "C:\Program Files\Mozilla Firefox\distribution"
New-Item -ItemType Directory -Path $ff -Force | Out-Null

@'
{
  "policies": {
    "Homepage": {
      "URL": "https://www.google.com",
      "StartPage": "homepage"
    }
  }
}
'@ | Out-File "$ff\policies.json" -Encoding UTF8