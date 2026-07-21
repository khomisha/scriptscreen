# ScriptScreen — Distribution Guide

The **web/Electron** distribution of ScriptScreen for Linux, Windows and macOS.
(The native Flutter `io` build is legacy and is being phased out.)

A distribution is a plain archive: the user unpacks it and runs one install
script. There is no platform installer/MSI and, on Windows, **no registry keys
are written for ScriptScreen itself**.

This page is an index. The full documentation lives in `dist/`:

| Document | For whom | Contents |
|----------|----------|----------|
| [dist/README.md](dist/README.md) | Maintainer | Building the distribution archives with `make-dist.sh`; archive layout. |
| [dist/vendor/README.md](dist/vendor/README.md) | Maintainer | Where to place the prebuilt whisper.cpp + ffmpeg payloads (speech models are not bundled — the installer downloads them). |
| [dist/BUILD_WHISPER.md](dist/BUILD_WHISPER.md) | Maintainer | Building the `whisper-cli` / `whisper-stream` binaries on each OS. |
| [dist/templates/common/INSTALL.md](dist/templates/common/INSTALL.md) | End user | Installing and uninstalling the app (also shipped inside each archive). |

> 🇷🇺 Russian version: [DISTRIBUTION.ru.md](DISTRIBUTION.ru.md)

## Quick start (maintainer)

```bash
# 1. Build whisper.cpp + ffmpeg and place them under dist/vendor/<platform>/
#    (see dist/BUILD_WHISPER.md and dist/vendor/README.md)
# 2. Build the archive:
dist/make-dist.sh --platform linux        # or windows | macos
# -> dist/out/scriptscreen-<version>-<platform>.{tar.gz|zip}
```
