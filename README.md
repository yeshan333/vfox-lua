<div align="center">

![logo](./assets/vfox-lua-logo.png)

[![E2E tests](https://github.com/yeshan333/vfox-lua/actions/workflows/e2e_test.yaml/badge.svg)](https://github.com/yeshan333/vfox-lua/actions/workflows/e2e_test.yaml)

</div>

# vfox-lua plugin

lua [vfox](https://github.com/version-fox) plugin. Use the vfox to manage multiple [lua](https://www.lua.org/ftp/) versions in Linux/Darwin MacOS.

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



## Acknowledgements

Thanks for these awesome resources that were used during the development of the **vfox-lua**:

- [lua](https://www.lua.org/)
- [version-fox](https://github.com/version-fox/vfox)
- [asdf-lua](https://github.com/Stratus3D/asdf-lua)
