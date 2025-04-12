<div align="center">

![logo](./assets/vfox-lua-logo.png)

[![E2E tests](https://github.com/yeshan333/vfox-lua/actions/workflows/e2e_test.yaml/badge.svg)](https://github.com/yeshan333/vfox-lua/actions/workflows/e2e_test.yaml)

</div>

# vfox-lua plugin

Lua [vfox](https://github.com/version-fox) plugin. Use the vfox to manage multiple [lua](https://www.lua.org/ftp/) versions on Linux、Darwin MacOS、Windows.

## Requirements

- MacOS/Linux (you can install by apt or homebrew)
  - GNU Make
  - ANSI C compiler (like gcc)
- Windows (you can install by [msys2](https://www.msys2.org/))
  - GCC Compiler
  - Make

## Usage

```shell
# install plugin
vfox add --source https://github.com/yeshan333/vfox-lua/archive/refs/heads/main.zip lua

# install an available lua version
vofx search lua
# or specific version 
vfox install lua@5.4.7
```

## Notice

1. Make sure build tools (gcc compiler、make or others) are in the system [$PATH](https://superuser.com/questions/284342/what-are-path-and-other-environment-variables-and-how-can-i-set-or-use-them).

2. If you are installing Lua 5.4.x or greater on Linux. By default, Lua will be compiled with readline. For build the interactive Lua interpreter with handy line-editing and history capabilities, you need to install the readline library.

3. Use `PowerShell` to install the Lua on Windows.

## Known Issue

- Lua versions 5.0 and earlier can not install on Linux.

## Acknowledgements

Thanks for these awesome resources that were used during the development of the **vfox-lua**:

- [lua](https://www.lua.org/)
- [version-fox](https://github.com/version-fox/vfox)
- [asdf-lua](https://github.com/Stratus3D/asdf-lua)
