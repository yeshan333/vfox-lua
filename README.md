<div align="center">

![logo](./assets/vfox-lua-logo.png)

[![E2E tests](https://github.com/yeshan333/vfox-lua/actions/workflows/e2e_test.yaml/badge.svg)](https://github.com/yeshan333/vfox-lua/actions/workflows/e2e_test.yaml)

</div>

# vfox-lua plugin

Lua [vfox](https://github.com/version-fox) plugin. Use the vfox to manage multiple [lua](https://www.lua.org/ftp/) versions on Linux, macOS, and Windows.

## Requirements

- macOS / Linux
  - GNU Make
  - ANSI C compiler (gcc or clang)
  - readline development library (`libreadline-dev` on Debian/Ubuntu, `readline` via Homebrew on macOS)
- Windows (install via [MSYS2](https://www.msys2.org/))
  - GCC compiler
  - Make

## Usage

### Install with vfox

```shell
# install plugin
vfox add --source https://github.com/yeshan333/vfox-lua/archive/refs/heads/main.zip lua

# search available versions
vfox search lua

# install a specific version
vfox install lua@5.4.7

# activate
vfox use -g lua@5.4.7
```

### Install with mise

The vfox-lua plugin can also be used through [mise](https://mise.jdx.dev/), which supports vfox plugins as a backend.

```shell
# install and activate
mise use -g vfox:yeshan333/lua@5.4.7

# run lua
mise exec -- lua -v
```

### LuaRocks Integration

LuaRocks can be automatically installed alongside Lua by setting the `VFOX_LUA_LUAROCKS` environment variable. This is supported on Linux and macOS only.

```shell
# vfox
VFOX_LUA_LUAROCKS=1 vfox install lua@5.4.7

# mise
VFOX_LUA_LUAROCKS=1 mise use -g vfox:yeshan333/lua@5.4.7
```

When enabled, the plugin will:

1. Fetch the latest LuaRocks release from GitHub (fallback: 3.11.1)
2. Build and bootstrap LuaRocks into `<install-dir>/luarocks/`
3. Add `luarocks` to `PATH` and configure `LUA_INIT` so that installed rocks are immediately available

```shell
# verify
luarocks --version

# install a rock
luarocks install luacheck
```

## Notice

1. Make sure build tools (gcc/clang, make) are in your system [`$PATH`](https://superuser.com/questions/284342/what-are-path-and-other-environment-variables-and-how-can-i-set-or-use-them).

2. Lua 5.4+ on Linux/macOS is compiled with readline by default. Install the readline development library before building:
   - Debian/Ubuntu: `sudo apt-get install libreadline-dev`
   - macOS: `brew install readline`

3. On Windows, use `PowerShell` to install Lua.

## Known Issues

- Lua versions 5.0 and earlier cannot be installed on Linux.
- LuaRocks integration is not available on Windows.

## Acknowledgements

- [Lua](https://www.lua.org/)
- [vfox](https://github.com/version-fox/vfox)
- [LuaRocks](https://luarocks.org/)
- [asdf-lua](https://github.com/Stratus3D/asdf-lua)
