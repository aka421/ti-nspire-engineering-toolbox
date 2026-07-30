# TI-Nspire Engineering Toolbox

A Lua-based engineering toolbox for the original TI-Nspire CX.

## Requirements

- TI-Nspire CX running OS 3.0.2 or newer
- macOS command-line tools (`xcode-select --install`)
- Git
- Homebrew and zlib if Luna does not compile with the system zlib
- TI-Nspire Computer Link for transferring the generated `.tns` file

## First-time setup

```bash
xcode-select --install
brew install zlib
./setup-luna.sh
```

## Build

```bash
./build.sh
```

The calculator-ready document is created at:

```text
dist/engineering_toolbox.tns
```

Upload that file with TI-Nspire Computer Link.
