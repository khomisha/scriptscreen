# Building ScriptScreen distributions

This directory produces the **web/Electron** distribution of ScriptScreen for
Linux, Windows and macOS. (The native Flutter `io` build is legacy and is being
phased out.)

A distribution is a plain archive: the user unpacks it and runs one install
script. There is no platform installer/MSI and, on Windows, **no registry keys
are written for ScriptScreen itself**.

## What the archive contains

```
scriptscreen-<version>-<platform>[-gpu-<backend>]/
├── app/            Flutter web build + Electron shell (no node_modules)
├── whisper/        prebuilt whisper.cpp build (no models)    -> installs to ~/whisper.cpp
├── ffmpeg/         bundled ffmpeg binary                      -> installs to ~/whisper.cpp/bin
├── install.{sh,command,ps1}
├── uninstall.{sh,command,ps1}
├── check-gpu.{sh,ps1}   (linux/windows) user-side GPU suitability test
├── INSTALL.md      end-user instructions (install + uninstall), English
├── INSTALL.ru.md   the same instructions in Russian
├── INSTALL.pdf     PDF of INSTALL.md
├── INSTALL.ru.pdf  PDF of INSTALL.ru.md
├── icon.png
└── VERSION
```

The end-user guide lives in `dist/templates/common/` in two languages
(`INSTALL.md`, `INSTALL.ru.md`). After editing either one, regenerate the PDFs
that ship alongside them:

```bash
dist/scripts/make-install-pdf.sh
```

It needs `python3` with `markdown-it-py` and a Chrome/Chromium binary on the
build host (end users need neither).

## One-time prerequisites (build host)

- Flutter SDK (the build was made with 3.29.x) on `PATH`.
- A prebuilt whisper.cpp and an ffmpeg binary for each target platform, placed
  under `dist/vendor/<platform>/`. **Produce them with the build script**
  (below) — it builds whisper.cpp with SDL2 and fetches ffmpeg, staging
  everything into `dist/vendor/<platform>/`. The manual steps and layout
  reference are in [BUILD_WHISPER.md](BUILD_WHISPER.md) / [vendor/README.md](vendor/README.md).
- Speech models are **not** part of the archive — they are large, and the
  install scripts download the selected ones from Hugging Face on the client
  machine (default: `small`; override with `--models` / `-Models`).
- `tar` (Linux/macOS targets) and `zip` or `python3` (Windows target).

## Step 1 — build the whisper.cpp vendor payload (per platform)

```bash
# Linux / macOS (auto-detected):
dist/scripts/build-whisper.sh
```
```powershell
# Windows (from the x64 Native Tools Command Prompt for VS 2022):
powershell -ExecutionPolicy Bypass -File dist\scripts\build-whisper.ps1 -Vcpkg C:\vcpkg
```

whisper.cpp is built statically with `WHISPER_SDL2=ON` (live transcription). On
Linux/macOS SDL2 stays a dynamic dependency and the **installer** installs it on
the client; on Windows `SDL2.dll` is bundled into the archive. No models are
downloaded or staged by default; pass `--models "small large-v3-turbo"` only if
you want to pre-bundle models for an offline install. Other useful flags:
`--ffmpeg download|build|skip|<path>`, `--gpu cuda|vulkan|metal|none`, `--log [file]`.
The Windows script always writes `dist\out\build-whisper-windows.log`
(`-Log <file>` overrides the path, `-NoLog` disables it).

If you build with `--gpu cuda` or `--gpu vulkan` (`-Gpu` on Windows), the
archive only benefits machines with the matching GPU/driver. The build script
records the backend in a `GPU_BACKEND` marker inside the vendor payload, and
`make-dist.sh` automatically names the archive
`scriptscreen-<version>-<platform>-gpu-<backend>.tar.gz|zip` so users can tell
the flavors apart. Each flavor is cached in its own
`dist/vendor/<platform>/whisper-<flavor>` directory (`cpu`, `vulkan`, `cuda`),
so build each flavor **once** — releasing an app-only change never needs a
whisper rebuild, and `make-dist.sh` packages every cached flavor in one run. Every Linux/Windows archive also ships a `check-gpu.sh` /
`check-gpu.ps1` the user can run **before installing** — it reports the
archive's GPU flavor, detects the NVIDIA driver (CUDA) and the Vulkan runtime,
and test-launches the archive's own `whisper-cli` to catch missing runtime
libraries, then prints a per-build verdict.

## Step 2 — assemble the archive (per platform)

```bash
# from the repo root
dist/make-dist.sh --platform linux
dist/make-dist.sh --platform windows
dist/make-dist.sh --platform macos
```

> **Windows build host:** `make-dist.sh` is a bash script — PowerShell/cmd
> cannot run it (`CommandNotFoundException`), and it needs **Git Bash**
> (installed with Git for Windows). **Open a Git Bash terminal first**, `cd` to
> the repo root and run `dist/make-dist.sh --platform windows` inside it — do
> not launch the script by double-clicking it or through a cmd/Explorer
> wrapper: that spawns a new console window which closes instantly on any
> error, so you never see what failed. If that does happen, the output is not
> lost — the script always writes `dist/out/make-dist-windows.log` (disable
> with `--no-log`).
> Alternatively, copy `dist\vendor\windows\` to a Linux/macOS build host and
> assemble the archive there — the `app/` payload is platform-independent, only
> `whisper/` and `ffmpeg/` are platform-specific.

The Flutter web bundle is always built with `--no-web-resources-cdn` (assets are
served locally by the Electron shell). Archives are written to `dist/out/` —
**one per whisper flavor cached in `dist/vendor/<platform>/`** (e.g. both the
CPU and the Vulkan archive from a single run, with the Flutter bundle built
once). Useful flags:

- `--gpu <flavor>` package only this cached whisper flavor: `cpu` | `vulkan` | `cuda`
- `--debug`       build the Flutter web bundle with `--debug` instead of `--release`
- `--skip-build`  reuse the existing `build/web` instead of running `flutter build web`
- `--skip-vendor` package without whisper/ffmpeg (produces a non-runnable archive; for plumbing tests only)
- `--with-models` bundle the `ggml-*.bin` models found in the vendor dir (default: excluded — the installer downloads them on the client)
- `--version X`   override the version (default: parsed from `pubspec.yaml`)
- `--log <file>`  write the log to a custom path (a log is always written by default: `dist/out/make-dist-<platform>.log`)
- `--no-log`      disable the log file

> The Flutter build must be produced **per platform's CPU only for the vendor
> binaries** — the Flutter web `app/` itself is platform-independent, so the same
> `build/web` is reused for all three archives. Only `whisper/` and `ffmpeg/`
> differ per platform.

## How it runs on the user's machine

The installer copies `app/` into a per-user location and runs
`npm install --omit=dev`, which pulls **Electron** and **pdf-lib** (declared in
`app/package.json`). A generated launcher prepends `~/whisper.cpp/bin` to `PATH`
(so the bundled ffmpeg is found) and starts the local Electron binary against the
app directory. whisper.cpp is read from `~/whisper.cpp` — the path the app
hardcodes in `simple-whisper.js`.
