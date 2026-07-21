<#
    ScriptScreen - Windows installer.

    Installs entirely under your user profile. It does NOT write any registry
    keys for ScriptScreen itself; the only registry changes that may occur come
    from third-party installers (Node.js via winget) when those tools are
    missing. App discovery uses a Start Menu shortcut (a .lnk file, not the
    registry).

    Run from the unpacked archive:
        Right-click install.ps1 > "Run with PowerShell", or:
        powershell -ExecutionPolicy Bypass -File .\install.ps1

    Options:
        -Models "small large-v3"  Models to ensure are present (default: "small").
                                  Missing ones are downloaded.
        -Log <file>               Write the install log to a custom file
                                  (default: %LOCALAPPDATA%\ScriptScreen\install.log).
        -NoLog                    Do not write a log file.

    SDL2 (needed for live transcription) ships as SDL2.dll inside the archive
    next to the whisper binaries, so nothing extra is installed on this machine.
#>
[CmdletBinding()]
param(
    [string]$Models = 'small',
    [string]$Log    = '',
    [switch]$NoLog
)
$ErrorActionPreference = 'Stop'

$SrcDir     = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$AppDir     = if ($env:SCRIPTSCREEN_HOME) { $env:SCRIPTSCREEN_HOME } else { Join-Path $env:LOCALAPPDATA 'ScriptScreen' }
$WhisperDir = Join-Path $env:USERPROFILE 'whisper.cpp'   # os.homedir() == USERPROFILE
$StartMenu  = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$Launcher   = Join-Path $AppDir 'scriptscreen.cmd'

function Log($m) { Write-Host "==> $m" }
function Die($m) { Write-Error $m; exit 1 }

if (-not (Test-Path (Join-Path $SrcDir 'app'))) { Die "Run this from the unpacked archive (app\ not found)." }

# Logging (on by default, -NoLog disables): mirror all output to a transcript.
$LogPath = $null
if (-not $NoLog) {
    if ([string]::IsNullOrWhiteSpace($Log)) { $Log = Join-Path $AppDir 'install.log' }
    $LogPath = $Log
    New-Item -ItemType Directory -Force -Path (Split-Path $LogPath) | Out-Null
    Start-Transcript -Path $LogPath -Append | Out-Null
    Log "Logging to $LogPath"
}

# ---------------------------------------------------------------------------
# 1. Node.js + npm (via winget if missing)
# ---------------------------------------------------------------------------
function Have($cmd) { return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

if (-not (Have 'node') -or -not (Have 'npm')) {
    if (Have 'winget') {
        Log "Node.js not found - installing via winget"
        winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
        # Refresh PATH for this session so node/npm are visible immediately.
        $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' +
                    [System.Environment]::GetEnvironmentVariable('Path','User')
    } else {
        Die "Node.js/npm not found and winget is unavailable. Install Node.js 18+ from https://nodejs.org and re-run."
    }
}
if (-not (Have 'node')) { Die "Node.js still not available after install (open a new terminal and re-run)." }
Log ("Using node " + (node --version) + ", npm " + (npm --version))

# ---------------------------------------------------------------------------
# 2. App + npm dependencies
# ---------------------------------------------------------------------------
Log "Installing app to $AppDir"
New-Item -ItemType Directory -Force -Path $AppDir | Out-Null
Copy-Item -Path (Join-Path $SrcDir 'app\*') -Destination $AppDir -Recurse -Force

Log "Installing npm dependencies (downloads Electron - needs network)"
Push-Location $AppDir
try { npm install --omit=dev --no-audit --no-fund } finally { Pop-Location }
if ($LASTEXITCODE -ne 0) { Log "WARNING: npm install exited with code $LASTEXITCODE" }

# The Electron binary is fetched from GitHub releases by a postinstall step.
# On networks where that download is blocked or reset, npm leaves
# node_modules\electron in place without the binary - and a plain re-run of
# npm install then skips the postinstall, so the tree never heals itself.
# Verify the binary and, if missing, retry the download through a mirror.
$ElectronPkg = Join-Path $AppDir 'node_modules\electron'
$ElectronExe = Join-Path $ElectronPkg 'dist\electron.exe'
if (-not (Test-Path $ElectronExe)) {
    Log "Electron binary missing (GitHub download failed?) - retrying via mirror"
    if (-not $env:ELECTRON_MIRROR) { $env:ELECTRON_MIRROR = 'https://npmmirror.com/mirrors/electron/' }
    if (Test-Path (Join-Path $ElectronPkg 'install.js')) {
        Push-Location $ElectronPkg
        try { node install.js } finally { Pop-Location }
    } else {
        # npm rolled the tree back on failure - run the whole install again
        # with the mirror active so the postinstall fetches from it.
        Push-Location $AppDir
        try { npm install --omit=dev --no-audit --no-fund } finally { Pop-Location }
    }
    if (-not (Test-Path $ElectronExe)) {
        Die "Electron download failed even via mirror ($env:ELECTRON_MIRROR). Set ELECTRON_MIRROR to a reachable mirror and re-run install.ps1."
    }
}

# ---------------------------------------------------------------------------
# 3. whisper.cpp + models -> %USERPROFILE%\whisper.cpp
# ---------------------------------------------------------------------------
if ((Test-Path (Join-Path $SrcDir 'whisper\build')) -or (Test-Path (Join-Path $SrcDir 'whisper\models'))) {
    Log "Installing whisper.cpp to $WhisperDir"
    New-Item -ItemType Directory -Force -Path $WhisperDir | Out-Null
    Copy-Item -Path (Join-Path $SrcDir 'whisper\*') -Destination $WhisperDir -Recurse -Force
} else {
    Log "WARNING: no whisper payload - transcription will not work until $WhisperDir is populated"
}

# ---------------------------------------------------------------------------
# 3a. Ensure speech models are present - download any missing ones.
# ---------------------------------------------------------------------------
$HfBase   = 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main'
$ModelDir = Join-Path $WhisperDir 'models'
foreach ($m in ($Models -split '\s+' | Where-Object { $_ })) {
    $dest = Join-Path $ModelDir "ggml-$m.bin"
    if (Test-Path $dest) { Log "Model '$m' already present"; continue }
    $remote = if ($m -eq 'turbo') { 'large-v3-turbo' } else { $m }  # UI 'turbo' -> large-v3-turbo
    Log "Downloading model '$m' (ggml-$remote.bin)"
    New-Item -ItemType Directory -Force -Path $ModelDir | Out-Null
    try {
        Invoke-WebRequest -Uri "$HfBase/ggml-$remote.bin" -OutFile "$dest.part"
        Move-Item -Force "$dest.part" $dest
    } catch {
        Remove-Item -Force "$dest.part" -ErrorAction SilentlyContinue
        Log "WARNING: failed to download model '$m': $_"
    }
}

# ---------------------------------------------------------------------------
# 4. Bundled ffmpeg.exe -> %USERPROFILE%\whisper.cpp\bin
# ---------------------------------------------------------------------------
$ffSrc = Join-Path $SrcDir 'ffmpeg\ffmpeg.exe'
if (Test-Path $ffSrc) {
    $ffBin = Join-Path $WhisperDir 'bin'
    Log "Installing bundled ffmpeg to $ffBin"
    New-Item -ItemType Directory -Force -Path $ffBin | Out-Null
    Copy-Item -Path $ffSrc -Destination (Join-Path $ffBin 'ffmpeg.exe') -Force
} elseif (Have 'ffmpeg') {
    Log "Using system ffmpeg on PATH"
} else {
    Log "WARNING: no bundled ffmpeg and none on PATH - non-WAV transcription will fail"
}

# ---------------------------------------------------------------------------
# 5. Launcher (.cmd) + Start Menu shortcut (.lnk file, no registry)
# ---------------------------------------------------------------------------
Log "Creating launcher $Launcher"
$cmd = @"
@echo off
rem ScriptScreen launcher (generated by install.ps1)
set "PATH=%USERPROFILE%\whisper.cpp\bin;%PATH%"
cd /d "$AppDir"
"%CD%\node_modules\.bin\electron.cmd" . %*
"@
Set-Content -Path $Launcher -Value $cmd -Encoding ASCII

if (Test-Path (Join-Path $SrcDir 'icon.png')) {
    Copy-Item (Join-Path $SrcDir 'icon.png') (Join-Path $AppDir 'icon.png') -Force
}

Log "Creating Start Menu shortcut"
$ws = New-Object -ComObject WScript.Shell
$lnk = $ws.CreateShortcut((Join-Path $StartMenu 'ScriptScreen.lnk'))
$lnk.TargetPath       = $Launcher
$lnk.WorkingDirectory = $AppDir
$lnk.WindowStyle      = 7   # minimized console window
$lnk.Description      = 'ScriptScreen editor with mind cards'
$lnk.Save()

Write-Host ""
Log "ScriptScreen installed."
Write-Host "    Launch from the Start Menu (ScriptScreen), or run:"
Write-Host "      `"$Launcher`""
Write-Host "    To uninstall: run .\uninstall.ps1 from this archive."

if ($LogPath) { Stop-Transcript | Out-Null }
