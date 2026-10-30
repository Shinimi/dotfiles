# yu's Windows 11 IoT Enterprise LTSC 2024 setup: runs once on first login (autounattend.xml starts it), or run it yourself
# as admin. Installs winget (LTSC ships without it), your apps, game runtimes, then removes what's left of the bloat and sets
# things up the way the Linux setup was: dark + grey, flat mouse, NumLock on, no web results in Start, no ads, no telemetry.
# Safe to run again. Log: C:\yu-setup.log. Made by Claude.
#Requires -RunAsAdministrator
$ErrorActionPreference = 'Continue'
Start-Transcript -Path "C:\yu-setup.log" -Append | Out-Null
function Say($t) { Write-Host "`n== $t" -ForegroundColor Cyan }

# ---------------------------------------------------------------- apps (edit freely: winget IDs, `winget search <name>`)
$apps = @(
  'Valve.Steam', 'Vencord.Vesktop', 'Brave.Brave', 'Waterfox.Waterfox',
  'Microsoft.WindowsTerminal', 'Microsoft.PowerShell', 'Fastfetch-cli.Fastfetch',
  '7zip.7zip', 'VideoLAN.VLC', 'voidtools.Everything', 'Microsoft.PowerToys', 'RamenSoftware.Windhawk',
  'OBSProject.OBSStudio', 'HeroicGamesLauncher.HeroicGamesLauncher',
  # game runtimes (most games need these; Steam installs some per game, these cover the rest)
  'Microsoft.VCRedist.2015+.x64', 'Microsoft.VCRedist.2015+.x86', 'Microsoft.DirectX', 'Microsoft.DotNet.DesktopRuntime.8'
)
$userApps = @('Spotify.Spotify')          # these refuse to install as admin: installed as you, without elevation
$lolRegion = 'tr'                         # League of Legends installer region: tr, euw, eune, na …

# ---------------------------------------------------------------- winget
Say 'winget (LTSC has no Store, so it comes from Microsoft directly)'
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  $t = Join-Path $env:TEMP 'winget'; New-Item -ItemType Directory -Force $t | Out-Null
  $ProgressPreference = 'SilentlyContinue'
  Invoke-WebRequest 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx' -OutFile "$t\vclibs.appx"
  Invoke-WebRequest 'https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx' -OutFile "$t\xaml.appx"
  Invoke-WebRequest 'https://aka.ms/getwinget' -OutFile "$t\winget.msixbundle"
  Add-AppxPackage "$t\vclibs.appx"; Add-AppxPackage "$t\xaml.appx"; Add-AppxPackage "$t\winget.msixbundle"
  $env:Path += ";$env:LOCALAPPDATA\Microsoft\WindowsApps"
}
winget source update --disable-interactivity | Out-Null

Say 'apps'
foreach ($id in $apps) {
  Write-Host "  $id"
  winget install -e --id $id --silent --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Null
}
foreach ($id in $userApps) {   # run unelevated, as the logged-in user
  Write-Host "  $id (as you)"
  & runas.exe /trustlevel:0x20000 "winget install -e --id $id --silent --accept-package-agreements --accept-source-agreements"
}

Say "League of Legends ($lolRegion)"
try {
  $lol = Join-Path $env:TEMP "lol-$lolRegion.exe"
  Invoke-WebRequest "https://lol.secure.dyn.riotcdn.net/channels/public/x/installer/current/live.$lolRegion.exe" -OutFile $lol
  Start-Process $lol   # Riot's own installer (Riot Client + Vanguard); needs TPM 2.0 + Secure Boot on in the BIOS
} catch { Write-Host "  couldn't download it: get it from leagueoflegends.com" -ForegroundColor Yellow }

# ---------------------------------------------------------------- debloat (LTSC is already lean: this is the rest)
Say 'debloat: telemetry, ads, suggestions, web search'
function Reg($path, $name, $value, $type = 'DWord') {
  if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
  New-ItemProperty -Path $path -Name $name -Value $value -PropertyType $type -Force | Out-Null
}
# telemetry off (Enterprise honours level 0) and its services
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0
foreach ($s in 'DiagTrack', 'dmwappushservice') { Stop-Service $s -Force -ErrorAction SilentlyContinue; Set-Service $s -StartupType Disabled -ErrorAction SilentlyContinue }
# ads, suggestions, "tips", auto-installed apps
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 1
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableSoftLanding' 1
Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0
$cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
foreach ($n in 'SilentInstalledAppsEnabled', 'SystemPaneSuggestionsEnabled', 'SoftLandingEnabled', 'SubscribedContent-338388Enabled',
               'SubscribedContent-338389Enabled', 'SubscribedContent-353694Enabled', 'SubscribedContent-353696Enabled', 'PreInstalledAppsEnabled', 'OemPreInstalledAppsEnabled') { Reg $cdm $n 0 }
Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement' 'ScoobeSystemSettingEnabled' 0
# Start menu: no Bing / web results, no activity history
Reg 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'PublishUserActivities' 0
# no peer-to-peer update sharing, no restart while you're logged in
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode' 0
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'NoAutoRebootWithLoggedOnUsers' 1
# OneDrive, if this build has it
$od = "$env:SystemRoot\System32\OneDriveSetup.exe"; if (Test-Path $od) { Start-Process $od '/uninstall' -Wait }

# ---------------------------------------------------------------- look & feel (like the Linux setup: dark, grey, clean)
Say 'look: dark, grey accent, clean taskbar, classic right-click menu'
$p = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
Reg $p 'AppsUseLightTheme' 0; Reg $p 'SystemUsesLightTheme' 0; Reg $p 'EnableTransparency' 1
Reg 'HKCU:\Software\Microsoft\Windows\DWM' 'AccentColor' 0xff3a3a3a; Reg 'HKCU:\Software\Microsoft\Windows\DWM' 'ColorPrevalence' 0
$adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Reg $adv 'HideFileExt' 0; Reg $adv 'Hidden' 1; Reg $adv 'LaunchTo' 1; Reg $adv 'TaskbarAl' 0
Reg $adv 'ShowTaskViewButton' 0; Reg $adv 'TaskbarDa' 0; Reg $adv 'ShowCopilotButton' 0
Reg $adv 'TaskbarEndTask' 1                                                   # right-click a taskbar app → End task
Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'SearchboxTaskbarMode' 1   # search as an icon
Reg 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' '(default)' '' 'String'   # full right-click menu

# ---------------------------------------------------------------- input (like Hyprland: flat mouse, NumLock on)
Say 'input: no mouse acceleration, NumLock on, no Sticky Keys pop-up'
Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' 'String'
Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' 'String'
Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' 'String'
Reg 'HKCU:\Control Panel\Keyboard' 'InitialKeyboardIndicators' '2' 'String'
Reg 'Registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard' 'InitialKeyboardIndicators' '2' 'String'
Reg 'HKCU:\Control Panel\Accessibility\StickyKeys' 'Flags' '506' 'String'

# ---------------------------------------------------------------- gaming & power
Say 'gaming: Game Mode on, Game DVR off, GPU scheduling on, high performance power'
Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1
Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' 'AllowGameDVR' 0
Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2
$ult = (powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61) -replace '.*GUID: ([0-9a-f-]+).*', '$1'
if ($ult -match '^[0-9a-f-]{36}$') { powercfg -setactive $ult } else { powercfg -setactive SCHEME_MIN }
# no hibernation / fast startup: frees disk space, and keeps the clock and drives right if Linux is on another drive
powercfg /h off
Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled' 0
Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' 'RealTimeIsUniversal' 1   # same clock as Linux

# ---------------------------------------------------------------- done
Say 'done'
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue   # taskbar/explorer pick up the changes
Write-Host @"

Almost done. Two things only you can do:
  1. Graphics driver: get AMD Software (Adrenalin) for the RX 9060 XT from amd.com/support (auto-detect tool).
  2. Restart once so every setting applies.
Log: C:\yu-setup.log
"@ -ForegroundColor Green
Stop-Transcript | Out-Null
Start-Process 'https://www.amd.com/en/support/download/drivers.html'
pause
