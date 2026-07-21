<#
    ScriptScreen - Windows uninstaller.

    Removes the app, launcher and Start Menu shortcut. Because the installer
    writes no registry keys for ScriptScreen, uninstalling is just deleting
    these files. Whisper models in %USERPROFILE%\whisper.cpp are kept unless
    you pass -Purge.

        powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 [-Purge]
#>
param([switch]$Purge)
$ErrorActionPreference = 'Stop'

$AppDir     = if ($env:SCRIPTSCREEN_HOME) { $env:SCRIPTSCREEN_HOME } else { Join-Path $env:LOCALAPPDATA 'ScriptScreen' }
$WhisperDir = Join-Path $env:USERPROFILE 'whisper.cpp'
$StartMenu  = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'

function Log($m) { Write-Host "==> $m" }

Log "Removing app at $AppDir"
if (Test-Path $AppDir) { Remove-Item -Recurse -Force $AppDir }

Log "Removing Start Menu shortcut"
Remove-Item -Force (Join-Path $StartMenu 'ScriptScreen.lnk') -ErrorAction SilentlyContinue

if ($Purge) {
    Log "Removing whisper.cpp and models at $WhisperDir (-Purge)"
    if (Test-Path $WhisperDir) { Remove-Item -Recurse -Force $WhisperDir }
} else {
    Write-Host "==> Kept $WhisperDir (whisper.cpp + models). Run with -Purge to remove it."
}

Log "ScriptScreen uninstalled."
Write-Host "    Note: Node.js was left installed (remove via 'winget uninstall OpenJS.NodeJS.LTS' if desired)."
