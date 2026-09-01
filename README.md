# ScriptScreen

**Write your screenplay on a board of plot cards.**

ScriptScreen is a free, open-source desktop app for writing screenplays. Every scene
is a plot card on an infinite board: drag it into place, tag it with characters,
locations, story details and time of action, then click a tag to filter the board
down to a single thread. Scene text is written in a built-in rich-text editor, and
can be dictated — speech recognition runs locally on your machine. Export the
finished script to PDF.

Linux and Windows. English and Russian interface. Apache 2.0.

> 🇷🇺 Русская версия: [README.ru.md](README.ru.md)

<!-- Add the demo here once recorded: ![ScriptScreen](docs/demo.gif) -->

## Features

- **Plot cards on an infinite board** — drag, resize, zoom and pan; Shift+Click to add a scene.
- **Four tag dimensions** — Roles, Locations, Details and Action Times, attached to any scene.
- **One-click filtering** — click a tag chip to show only the scenes carrying it; tags combine.
- **Built-in script editor** — full rich-text editing of scene bodies, saved automatically.
- **Offline dictation** — transcribe audio files or live microphone input via whisper.cpp, locally.
- **Front matter** — title page, logline and synopsis kept with the script.
- **PDF export** — the assembled screenplay, scenes in index order.
- **Your files stay yours** — a project is plain JSON plus HTML scene files on your disk;
  changing the name or version keeps a separate version of the script instead of
  overwriting the previous one.
- **No account, no cloud, no telemetry.**

## Installation

Download the archive for your platform from the
[v1.3.1 release](https://github.com/khomisha/scriptscreen/releases/tag/v1.3.1),
unpack it and run the install script. Everything is installed under your user
account — no administrator rights are required.

| Platform | Download | Install command |
|---|---|---|
| Linux | [`scriptscreen-1.3.1-linux.tar.gz`](https://github.com/khomisha/scriptscreen/releases/download/v1.3.1/scriptscreen-1.3.1-linux.tar.gz) | `./install.sh` |
| Linux, GPU | [`scriptscreen-1.3.1-linux-gpu-vulkan.tar.gz`](https://github.com/khomisha/scriptscreen/releases/download/v1.3.1/scriptscreen-1.3.1-linux-gpu-vulkan.tar.gz) | `./install.sh` |
| Windows | [`scriptscreen-1.3.1-windows.zip`](https://github.com/khomisha/scriptscreen/releases/download/v1.3.1/scriptscreen-1.3.1-windows.zip) | right-click `install.ps1` ▸ **Run with PowerShell** |
| Windows, GPU | [`scriptscreen-1.3.1-windows-gpu-vulkan.zip`](https://github.com/khomisha/scriptscreen/releases/download/v1.3.1/scriptscreen-1.3.1-windows-gpu-vulkan.zip) | right-click `install.ps1` ▸ **Run with PowerShell** |

**Which build?** The plain archive transcribes speech on the CPU and works
everywhere. The `gpu-vulkan` archive runs the speech models on a Vulkan-capable
GPU, which makes dictation — live transcription especially — noticeably faster.
If you are unsure, take the plain one.

The installer also sets up the components used for dictation: whisper.cpp speech
models and ffmpeg, placed under `~/whisper.cpp`.

macOS is supported by the code but not published as a build yet — build it from
source with `dist/make-dist.sh --platform macos` (see [DISTRIBUTION.md](DISTRIBUTION.md)).

Full installation, uninstallation and troubleshooting instructions:
[DISTRIBUTION.md](DISTRIBUTION.md) ([ru](DISTRIBUTION.ru.md)). The same guide ships
inside every archive as `INSTALL.md` / `INSTALL.ru.md`.

## Documentation

- [User Manual (English)](USER_MANUAL_EN.md)
- [Руководство пользователя (русский)](USER_MANUAL.md)
- [Distribution guide](DISTRIBUTION.md) — building the archives, for maintainers.

## Getting started

1. Open the app and create a project (**Project** panel ▸ menu ▸ *New Project*).
2. Go to the **Notes** panel and **Shift+Click** the board to add your first plot card.
3. Add characters, locations, details and action times in their own panels, then tag
   the card with them.
4. Select the card and write the scene in the editor — or dictate it.
5. Export the finished script to PDF from the **Project** panel.

## License

[Apache License 2.0](LICENSE).

## Support Me

**ETH**: `0xD28545A4a16C0857cD8af84185CcaAa9Bbef675e`  
**BTC**: `bc1q20nv9jj0zt04e0sa4h6s8xgyur70e48ue2de5r`  
**SOL**: `596MbbR8XGhFbCHzhWGgJEmPe42VjT7bSpMbUPBV41TU`  
**TRX**: `TSKCpMdPswcqRbBEmnq2cseQ6zr9XiwdDX`
