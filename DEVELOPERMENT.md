# Developer Guide

## End-to-end installation tests

The E2E workflow builds the latest commit on vfox's `main` branch for every run
and prints the tested commit SHA in the build log. It tests real installs on
Linux, macOS and Windows, plus mise on Linux and macOS. It installs the checked-out
plugin, so the PR's actual contents are tested. CI also covers Windows LuaBinaries,
LuaRocks opt-out, project version selection and static library linking.

Lua specifications use Busted and run against the installed SDK through `vfox exec`
or `mise exec`. The specifications verify the requested Lua version, compilation
and execution of bytecode, and loading a native LuaRocks module. On Unix, run:

```shell
export LUA_VERSION=5.4.7
vfox exec "lua@$LUA_VERSION" -- luarocks install busted
vfox exec "lua@$LUA_VERSION" -- busted --verbose spec/e2e

# For a Lua SDK installed through mise:
mise exec -- luarocks install busted
mise exec -- busted --verbose spec/e2e
```

Windows installation and LuaRocks opt-out scenarios use command-line E2E checks,
since those installations do not include LuaRocks.

Use a disposable runner or VM when reproducing the installation steps from
`.github/workflows/e2e_test.yaml`.

The `files` helper uses native `fs.copy`/`fs.remove` on vfox and keeps a fallback for
mise, which does not yet provide `fs`. mise's Lua 5.1 async functions cannot yield
through `pcall`, so its HTTP `try_get`/`try_download_file` APIs return errors directly.
Optional LuaRocks extraction uses a quoted `tar` fallback on mise; vfox uses its
native archive library. Both extract into a dedicated source directory.

## Releasing the plugin

After changes are merged, open **Actions → Plugin → Run workflow** on `main` and
enter a stable plugin version without `v`, for example `1.4.0`. The shared workflow
updates `PLUGIN.version`, creates the version commit and tag, and publishes the
plugin ZIP and manifest in this repository using `GITHUB_TOKEN`.

```shell
gh workflow run publish.yaml --repo yeshan333/vfox-lua --ref main -f version=1.4.0
```

Pull requests run package checks only; their titles do not trigger publication.
Existing `vX.Y.Z` tag pushes remain supported when `PLUGIN.version` matches the tag.
If publication fails, rerun the original failed job to resume the same release.

The caller follows the shared `@v1` workflows. See the
[public release documentation](https://github.com/version-fox/plugin-manifest-action)
for package contents, repository permissions and failure recovery.

## Lua in Windows

```powershell
❯ dumpbin.exe /dependents .\bin\lua.exe
Microsoft (R) COFF/PE Dumper Version 14.40.33811.0
Copyright (C) Microsoft Corporation.  All rights reserved.


Dump of file .\bin\lua.exe

File Type: EXECUTABLE IMAGE

  Image has the following dependencies:

    KERNEL32.dll
    msvcrt.dll
    lua54.dll

  Summary

        1000 .bss
        1000 .data
        1000 .idata
        1000 .pdata
        2000 .rdata
        1000 .reloc
        1000 .rsrc
        9000 .text
        1000 .tls
        1000 .xdata

> dumpbin.exe /dependents .\bin\luac.exe
Microsoft (R) COFF/PE Dumper Version 14.40.33811.0
Copyright (C) Microsoft Corporation.  All rights reserved.


Dump of file .\bin\luac.exe

File Type: EXECUTABLE IMAGE

  Image has the following dependencies:

    KERNEL32.dll
    msvcrt.dll

  Summary

        1000 .bss
        1000 .data
        5000 .debug_abbrev
        1000 .debug_aranges
        2000 .debug_frame
       19000 .debug_info
        C000 .debug_line
        3000 .debug_line_str
        E000 .debug_loclists
        1000 .debug_rnglists
        1000 .debug_str
        1000 .edata
        1000 .idata
        2000 .pdata
        6000 .rdata
        1000 .reloc
        1000 .rsrc
       2D000 .text
        1000 .tls
        2000 .xdata
```
