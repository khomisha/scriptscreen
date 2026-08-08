# Vendor payloads (prebuilt, per-platform)

`make-dist.sh` copies platform-specific binaries from here into the archive.
These are **not** committed to git (see `.gitignore`) because they are large and
platform-specific — you build/download them once and drop them in before
packaging.

Expected layout (only the platform you are packaging needs to exist). Whisper
payloads are cached **per GPU flavor** (`whisper-cpu`, `whisper-vulkan`,
`whisper-cuda`) so several flavors coexist and `make-dist.sh` packages each of
them without rebuilding whisper when only the app changed. A legacy single
`whisper/` directory is still understood (its flavor is read from the
`GPU_BACKEND` marker) and gets migrated to its flavored name by the next
build-whisper run:

```
dist/vendor/
├── linux/
│   ├── whisper-cpu/                       (one dir per built flavor: cpu | vulkan | cuda)
│   │   ├── build/bin/whisper-cli
│   │   ├── build/bin/whisper-stream
│   │   └── models/                       (empty — models are downloaded at install time)
│   ├── whisper-vulkan/
│   │   └── ...                            (same layout + GPU_BACKEND marker)
│   └── ffmpeg/
│       └── ffmpeg                         (static x86_64 build, shared by all flavors)
├── windows/
│   ├── whisper-<flavor>/
│   │   ├── build/bin/whisper-cli.exe
│   │   ├── build/bin/whisper-stream.exe
│   │   └── models/
│   └── ffmpeg/
│       └── ffmpeg.exe
└── macos/
    ├── whisper-<flavor>/
    │   ├── build/bin/whisper-cli
    │   ├── build/bin/whisper-stream
    │   └── models/
    └── ffmpeg/
        └── ffmpeg
```

Speech models (`ggml-*.bin`) are **not** part of the vendor payload or the
archive — the install scripts download the selected ones from Hugging Face on
the client machine. Any `ggml-*.bin` present here is excluded by `make-dist.sh`
unless you pass `--with-models` (offline installs).

The directory structure under `whisper-<flavor>/` mirrors exactly what the app
expects at runtime (`~/whisper.cpp/build/bin/...` and `~/whisper.cpp/models/...`),
because `make-dist.sh` stages the chosen flavor as `whisper/` inside the archive
and the installer copies it straight into `~/whisper.cpp`.

## Building whisper.cpp

Full per-platform build instructions (Linux, macOS, Windows), including SDL2
setup for live transcription and how to stage the output here, are in
**[../BUILD_WHISPER.md](../BUILD_WHISPER.md)**.

Short version:

```bash
git clone https://github.com/ggml-org/whisper.cpp
cd whisper.cpp
cmake -B build -DBUILD_SHARED_LIBS=OFF -DWHISPER_SDL2=ON   # SDL2 = live (whisper-stream)
cmake --build build --config Release -j
```

Then copy `build/bin/whisper-cli` and `build/bin/whisper-stream` into the
matching `dist/vendor/<platform>/whisper-<flavor>/` tree above. Build whisper.cpp
**on each target platform** so the binaries match.

## ffmpeg (LGPL build only)

Drop a static `ffmpeg` (`ffmpeg.exe` on Windows) into
`dist/vendor/<platform>/ffmpeg/`.

**Use an LGPL-2.1 build, not a GPL one.** The popular "full/static" builds
(johnvansickle, gyan.dev "full", evermeet) are compiled with `--enable-gpl`
(x264, etc.) and are therefore GPL — avoid them. ScriptScreen needs only WAV/
PCM conversion, which the LGPL build covers.

LGPL prebuilt binaries (look for `-lgpl` in the filename):

- Linux:   https://github.com/BtbN/FFmpeg-Builds/releases  — `ffmpeg-*-linux64-lgpl-*.tar.xz`
- Windows: https://github.com/BtbN/FFmpeg-Builds/releases  — `ffmpeg-*-win64-lgpl-*.zip`
- macOS:   no common prebuilt LGPL static build — compile from source:
  ```bash
  ./configure --disable-gpl --disable-nonfree --enable-static --disable-shared
  make -j
  ```

Confirm the build is LGPL before shipping:

```bash
ffmpeg -version | grep -o 'enable-gpl'   # must print NOTHING
```

We ship ffmpeg as a **standalone executable invoked as a subprocess** (no
linking into ScriptScreen), so the only LGPL obligation is the notice + a pointer
to the source — both already covered by the `FFmpeg` entry in
`assets/cfg/notice.json` (license `LGPL-2.1-or-later`, url `https://ffmpeg.org/`).
