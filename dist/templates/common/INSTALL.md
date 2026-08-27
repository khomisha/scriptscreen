# ScriptScreen — Installation Guide

> 🇷🇺 Russian version: [INSTALL.ru.md](INSTALL.ru.md)

ScriptScreen is distributed as a single archive. After unpacking it and running
the install script for your platform, the application is ready to use. The
installer also sets up the third-party components it needs (Node.js/npm,
whisper.cpp speech models, and ffmpeg).

Everything is installed **under your user account** — administrator/root rights
are only requested if Node.js or ffmpeg have to be installed system-wide.

---

## What gets installed, and where

| Component | Location | Notes |
|-----------|----------|-------|
| Application (Flutter + Electron) | Linux: `~/.local/share/scriptscreen`<br>macOS: `~/Library/Application Support/ScriptScreen`<br>Windows: `%LOCALAPPDATA%\ScriptScreen` | Includes a local copy of Electron pulled by `npm install`. |
| Speech recognition (whisper.cpp + models) | `~/whisper.cpp` (Windows: `%USERPROFILE%\whisper.cpp`) | The app reads this fixed path. Large; kept on uninstall unless you purge. |
| ffmpeg (audio conversion) | `~/whisper.cpp/bin` | Bundled; used only when importing non‑WAV audio. |
| Launcher / menu entry | Linux: `~/.local/bin/scriptscreen` + menu entry<br>macOS: `~/Applications/ScriptScreen.command`<br>Windows: Start Menu shortcut | — |

> **Windows note:** the installer writes **no registry keys** for ScriptScreen.
> App discovery is a Start Menu shortcut file only. (Installing Node.js via
> winget, if it is missing, is a separate third-party step that may touch the
> registry.)

---

## Requirements

- A working internet connection for the first install (to download Electron,
  the speech models, and — if missing — Node.js). The archive does not include
  speech models — the installer downloads the ones you select.
- ~1.5 GB free disk space plus the size of the speech models you install
  (`small` ≈ 0.5 GB, `large-v3` ≈ 3 GB).
- Node.js 18 or newer. The installer will install it for you if it is missing
  (Linux: system package manager; macOS: Homebrew; Windows: winget).
- **SDL2** is required for *live* transcription. On Linux/macOS the installer
  installs it for you (Linux: package manager, `sudo`; macOS: Homebrew). On
  Windows `SDL2.dll` is bundled inside the archive — nothing to install.

## GPU builds — check your machine first

Some archives are built with GPU acceleration (CUDA for NVIDIA cards, or
Vulkan) — you can recognize them by `-gpu-cuda` / `-gpu-vulkan` in the archive
name. Before installing such an archive, run the check script from the
unpacked archive — it tells you whether this machine can use it:

```bash
# Linux
./check-gpu.sh
```
```powershell
# Windows
powershell -ExecutionPolicy Bypass -File .\check-gpu.ps1
```

It checks for an NVIDIA driver (CUDA), a Vulkan runtime, and tries to start
the archive's own whisper binary, then prints a verdict per build type. It is
read-only — nothing is installed or changed. If it says the archive's binaries
do not start on your machine, use the CPU build instead: it works everywhere,
just slower on long recordings. (On macOS, GPU acceleration via Metal is
automatic — there is nothing to check.)

## Installer options

The install script accepts a couple of optional flags:

- `--models "<a> <b>"` — speech models to make sure are present; any that are
  missing are downloaded from Hugging Face (default: `small`). Names match the
  ScriptScreen UI, e.g. `small`, `medium`, `large-v3`, `turbo`.
- `--log <file>` (Windows: `-Log <file>`) — write the install log to a custom
  file. By default the installer **always** writes everything it prints to
  `install.log` inside the app directory (see the table above) — attach that
  file when reporting a problem.
- `--no-log` (Windows: `-NoLog`) — do not write a log file.

```bash
# Linux example: install and pre-download two models
./install.sh --models "small large-v3"
```
```powershell
# Windows example
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Models "small"
```

---

## Linux

1. Unpack the archive:
   ```bash
   tar -xzf scriptscreen-<version>-linux.tar.gz
   cd scriptscreen-<version>-linux
   ```
2. Run the installer:
   ```bash
   ./install.sh
   ```
   If Node.js/npm is missing it will be installed with your package manager
   (`apt`, `dnf`, `pacman` or `zypper`), which requires your `sudo` password.
3. Launch ScriptScreen from your application menu, or run `scriptscreen` in a
   terminal. (If the command is not found, add `~/.local/bin` to your `PATH` —
   the installer prints the exact line to add.)

---

## macOS

1. Unpack the archive (double-click the `.tar.gz` in Finder, or use Terminal):
   ```bash
   tar -xzf scriptscreen-<version>-macos.tar.gz
   cd scriptscreen-<version>-macos
   ```
2. Run the installer by double-clicking **`install.command`** in Finder, or:
   ```bash
   ./install.command
   ```
   If Node.js is missing, Homebrew is used (and installed first if necessary).
   The installer clears the Gatekeeper "quarantine" flag on the bundled binaries
   so they can run.
3. Launch ScriptScreen by double-clicking **`ScriptScreen.command`** in
   *Home ▸ Applications* (Finder ▸ Go ▸ Home).

   > If macOS still blocks a component, right-click it ▸ **Open**, then confirm
   > once. This is only needed the first time.

---

## Windows

1. Unpack the archive: right-click `scriptscreen-<version>-windows.zip` ▸
   **Extract All…**, then open the extracted folder.
2. Run the installer — right-click **`install.ps1`** ▸ **Run with PowerShell**,
   or from a PowerShell window in that folder:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\install.ps1
   ```
   If Node.js is missing it is installed via **winget**. After a fresh Node.js
   install you may need to open a new terminal and re-run the script so `node`
   is on the `PATH`.
3. Launch ScriptScreen from the **Start Menu** (search "ScriptScreen"), or run
   `scriptscreen.cmd` from `%LOCALAPPDATA%\ScriptScreen`.

---

## Uninstalling

Run the uninstall script from the same unpacked archive folder. By default this
removes the application, launcher and menu entry but **keeps** the large speech
models in `~/whisper.cpp`. Add the purge flag to remove those too.

**Linux**
```bash
./uninstall.sh           # keep ~/whisper.cpp
./uninstall.sh --purge   # also remove ~/whisper.cpp
```

**macOS**
```bash
./uninstall.command          # keep ~/whisper.cpp
./uninstall.command --purge  # also remove ~/whisper.cpp
```

**Windows**
```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1           # keep whisper.cpp
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1 -Purge    # also remove it
```

Because nothing is written to the Windows registry and everything lives under
your user profile, uninstalling is simply the removal of these files. Node.js,
Homebrew and any system ffmpeg are left in place — remove them separately if you
no longer need them.

---

## Troubleshooting

- **"node/npm not found" after install on Windows** — open a *new* PowerShell
  window (so the updated `PATH` is loaded) and re-run `install.ps1`.
- **App starts but transcription fails** — check that `~/whisper.cpp/build/bin`
  contains `whisper-cli`/`whisper-stream` and that `~/whisper.cpp/models`
  contains the `ggml-*.bin` model you selected in the app.
- **Importing MP3/M4A fails, WAV works** — ffmpeg is missing. Confirm
  `~/whisper.cpp/bin/ffmpeg` exists, or install ffmpeg system-wide.
- **`npm install` failed** — re-run the installer; it is safe to run again. Most
  failures here are a dropped network connection while downloading Electron.
- **Electron download fails repeatedly (`ECONNRESET` in the npm log)** — the
  Electron binary is downloaded from GitHub releases, which some networks block
  or reset. The installer automatically retries via a mirror; to use a
  different mirror, set `ELECTRON_MIRROR` before re-running the installer,
  e.g. `ELECTRON_MIRROR=https://npmmirror.com/mirrors/electron/`
  (PowerShell: `$env:ELECTRON_MIRROR = 'https://npmmirror.com/mirrors/electron/'`).
