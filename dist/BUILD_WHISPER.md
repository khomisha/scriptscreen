# Building whisper.cpp for the ScriptScreen distribution

> **Automated path.** `dist/scripts/build-whisper.sh` (Linux/macOS) and
> `dist/scripts/build-whisper.ps1` (Windows) do everything on this page —
> clone + static SDL2 build, ffmpeg — and stage the result into
> `dist/vendor/<platform>/`. Use them unless you need to customise the build:
>
> ```bash
> dist/scripts/build-whisper.sh --log
> ```
> ```powershell
> powershell -ExecutionPolicy Bypass -File dist\scripts\build-whisper.ps1 -Vcpkg C:\vcpkg
> ```
>
> The Windows script always writes `dist\out\build-whisper-windows.log`
> (`-Log <file>` overrides the path, `-NoLog` disables it).
>
> The rest of this document is the manual reference the scripts automate, and
> explains the SDL2 / ffmpeg licensing choices.

ScriptScreen calls two whisper.cpp binaries and a set of GGML models:

| Binary | Used for |
|--------|----------|
| `whisper-cli`    | transcribing a recorded audio file |
| `whisper-stream` | **live** transcription (requires **SDL2**) |

At runtime the app reads them from a fixed location (`web/simple-whisper.js`):

```
~/whisper.cpp/build/bin/whisper-cli        (whisper-cli.exe on Windows)
~/whisper.cpp/build/bin/whisper-stream      (whisper-stream.exe on Windows)
~/whisper.cpp/models/ggml-<model>.bin
```

For packaging, build whisper.cpp **on each target OS** and copy the results into
`dist/vendor/<platform>/whisper-<flavor>/` (flavor: `cpu` | `vulkan` | `cuda`)
with this exact layout (`make-dist.sh` stages it as `whisper/` inside the
archive and the installer copies that verbatim to `~/whisper.cpp`):

```
dist/vendor/<platform>/whisper-<flavor>/
├── build/bin/whisper-cli[.exe]
├── build/bin/whisper-stream[.exe]
├── build/bin/*.dll  or  *.so / *.dylib   (only if you build shared libs — see notes)
├── models/                                (empty — models are downloaded at install time)
└── GPU_BACKEND                            (only for vulkan/cuda flavors: the backend name)
```

Flavors are cached side by side, so `make-dist.sh` can package all of them (one
archive per flavor) without rebuilding whisper when only the app changed. The
build-whisper scripts stage this layout automatically; a legacy single
`dist/vendor/<platform>/whisper/` directory (as in the manual examples below)
also still works and is migrated on the next build-whisper run.

> **Build on the OS you target.** whisper.cpp produces native binaries; a Linux
> build will not run on Windows or macOS. Cross-compiling is possible but out of
> scope here.

---

## Models

**Models are not bundled into the distribution archive** — they are large
(`small` ≈ 0.5 GB, `large-v3` ≈ 3 GB), so the per-platform install scripts
download the selected ones from Hugging Face on the client machine (default:
`small`; override with `--models` / `-Models`).

The app loads the file as `ggml-<model>.bin` where `<model>` is **exactly** the
value selected in ScriptScreen's UI. The UI exposes: `tiny`, `base`, `small`,
`medium`, `large`, `large-v2`, `large-v3`, `turbo`. The installers map the UI's
**`turbo`** entry to the `large-v3-turbo` weights automatically.

If you need an **offline-installable** archive, you can still pre-bundle models:
download them into the whisper.cpp checkout —

```bash
# Linux / macOS
./models/download-ggml-model.sh small
./models/download-ggml-model.sh large-v3-turbo
```
```bat
:: Windows (from the repo root, in cmd)
models\download-ggml-model.cmd small
```

— rename `ggml-large-v3-turbo.bin` to `ggml-turbo.bin` if you offer `turbo`,
copy the chosen `ggml-*.bin` files into
`dist/vendor/<platform>/whisper/models/`, and package with
`dist/make-dist.sh --with-models`. (The build scripts do all of this when passed
`--models "<a> <b>"` / `-Models "<a> <b>"`.)

---

## Linux

**1. Install build tools + SDL2** (SDL2 is required for `whisper-stream`):

```bash
# Debian / Ubuntu
sudo apt-get update
sudo apt-get install -y build-essential cmake git libsdl2-dev

# Fedora
sudo dnf install -y gcc-c++ make cmake git SDL2-devel
```

**2. Clone and build (static libs → easiest to distribute):**

```bash
git clone https://github.com/ggml-org/whisper.cpp
cd whisper.cpp

cmake -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF \
  -DWHISPER_SDL2=ON
cmake --build build --config Release -j"$(nproc)"
```

Binaries are in `build/bin/`. With `BUILD_SHARED_LIBS=OFF` they are
self-contained except for SDL2, which is dynamically linked — either keep
`libsdl2` installed on target machines, or build SDL2 statically. To check what a
binary still needs:

```bash
ldd build/bin/whisper-stream    # any "not found" lines must be shipped/installed
```

**3. (Optional) GPU acceleration** — add **one** of:

- `-DGGML_VULKAN=ON` — **recommended GPU flavor for distribution**: one build
  covers NVIDIA, AMD and Intel GPUs, and end users only need their normal
  graphics driver. No GPU is required on the *build* machine (shaders are
  precompiled by `glslc`). Build deps:

  ```bash
  # Debian / Ubuntu
  sudo apt-get install -y libvulkan-dev glslc spirv-headers
  # Fedora
  sudo dnf install -y vulkan-headers vulkan-loader-devel glslc spirv-headers-devel
  ```

  The resulting binaries dynamically link `libvulkan.so.1`; `install.sh`
  installs the loader on the client automatically (package `libvulkan1` /
  `vulkan-loader`). On a machine without a Vulkan-capable GPU the binaries
  fall back to the CPU.

- `-DGGML_CUDA=ON` — NVIDIA only; needs the CUDA Toolkit (`nvcc`) at build
  time, and the client needs the CUDA runtime libraries (bundle them or
  require a CUDA install) — usually not worth it over Vulkan for
  distribution. When building on a machine without an NVIDIA GPU, also pass
  an explicit `-DCMAKE_CUDA_ARCHITECTURES="61;70;75;80;86;89;90"` ('native'
  detection fails without a device).

Leave both off for the widest-compatibility CPU build.
`build-whisper.sh --gpu vulkan|cuda` handles all of the above automatically.

**4. Stage it:**

```bash
mkdir -p dist/vendor/linux/whisper/build/bin dist/vendor/linux/whisper/models
cp build/bin/whisper-cli build/bin/whisper-stream dist/vendor/linux/whisper/build/bin/
```

---

## macOS

**1. Install tools** (Xcode Command Line Tools + Homebrew packages):

```bash
xcode-select --install                 # if not already installed
brew install cmake sdl2 git
```

**2. Clone and build** (Metal GPU is enabled by default on Apple Silicon):

```bash
git clone https://github.com/ggml-org/whisper.cpp
cd whisper.cpp

cmake -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF \
  -DWHISPER_SDL2=ON
cmake --build build --config Release -j"$(sysctl -n hw.ncpu)"
```

Binaries are in `build/bin/`. SDL2 is linked from Homebrew; verify and, if
needed, ship the dylib next to the binary or instruct users to `brew install sdl2`:

```bash
otool -L build/bin/whisper-stream      # shows linked dylibs (e.g. libSDL2)
```

> Build on the same CPU architecture you target (Apple Silicon `arm64` vs Intel
> `x86_64`), or pass `-DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"` for a universal
> binary. The bundled binaries are **unsigned** — the ScriptScreen installer
> already strips the Gatekeeper quarantine flag after copying them.

**3. Stage it:**

```bash
mkdir -p dist/vendor/macos/whisper/build/bin dist/vendor/macos/whisper/models
cp build/bin/whisper-cli build/bin/whisper-stream dist/vendor/macos/whisper/build/bin/
```

---

## Windows

**1. Install tools:**

- **Visual Studio 2022** (Community is fine) with the *"Desktop development with
  C++"* workload — provides MSVC and the CMake integration.
- **Git** for Windows.
- **SDL2** (required for `whisper-stream`). Easiest via **vcpkg**:
  ```bat
  git clone https://github.com/microsoft/vcpkg
  .\vcpkg\bootstrap-vcpkg.bat
  .\vcpkg\vcpkg install sdl2:x64-windows
  ```

**2. Clone and build** from the *x64 Native Tools Command Prompt for VS 2022*:

```bat
git clone https://github.com/ggml-org/whisper.cpp
cd whisper.cpp

cmake -B build ^
  -DWHISPER_SDL2=ON ^
  -DCMAKE_TOOLCHAIN_FILE=C:\path\to\vcpkg\scripts\buildsystems\vcpkg.cmake
cmake --build build --config Release -j
```

With the MSVC (multi-config) generator the binaries land in
**`build\bin\Release\`**, not `build\bin\`.

**3. Collect the runtime DLLs.** A default Windows build links shared libraries,
so the `.exe` files need their DLLs in the **same folder**. Copy *everything* from
`build\bin\Release\` (the `.exe` plus `ggml*.dll`, `whisper.dll`) and the
`SDL2.dll` (from vcpkg `installed\x64-windows\bin\` or the build output). To
verify what an exe needs, use *Dependencies* (https://github.com/lucasg/Dependencies)
or `dumpbin /dependents build\bin\Release\whisper-stream.exe`.

**4. Stage it** (note: the vendor layout flattens `Release\` into `build\bin\`):

```bat
mkdir dist\vendor\windows\whisper\build\bin
mkdir dist\vendor\windows\whisper\models
copy build\bin\Release\*.exe  dist\vendor\windows\whisper\build\bin\
copy build\bin\Release\*.dll  dist\vendor\windows\whisper\build\bin\
copy <sdl2>\SDL2.dll          dist\vendor\windows\whisper\build\bin\
```

Make sure the final names are `whisper-cli.exe` and `whisper-stream.exe` (the app
appends `.exe` implicitly, so the base names must match).

---

## Quick verification

After staging, smoke-test the file binary against a model before packaging
(download one first, e.g. `./models/download-ggml-model.sh small` — it is only
used for the test and is not shipped):

```bash
# Linux / macOS
~/whisper.cpp/build/bin/whisper-cli -m ~/whisper.cpp/models/ggml-small.bin -f samples/jfk.wav
```
```bat
:: Windows
%USERPROFILE%\whisper.cpp\build\bin\whisper-cli.exe -m %USERPROFILE%\whisper.cpp\models\ggml-small.bin -f samples\jfk.wav
```

If it prints a transcription, the binary + model are good. Then build the
archive with `dist/make-dist.sh --platform <platform>` — on Windows run it from
**Git Bash** (`bash dist/make-dist.sh --platform windows`); it is a bash script,
so PowerShell/cmd cannot run it.
