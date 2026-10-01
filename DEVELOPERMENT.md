# Developer Guide

## Test and debug hooks

The offline tests use `vfox plugin test` and `require("vfox.test")`, with fixture HTTP
responses and explicit environment overrides. Shell commands are stubbed; the suite
covers download selection, network errors, build failure, LuaRocks opt-out and cleanup,
Windows executable aliases, and activation paths.

These commands are on the vfox development branch and are not included in stable
v1.0.12. CI builds revision `930f5be15338fa1e330e5148d9670f8df8a3c9a4` for the
hook tests. Build that revision to run the same checks locally:

```shell
git clone https://github.com/version-fox/vfox.git /tmp/vfox-tests
git -C /tmp/vfox-tests checkout 930f5be15338fa1e330e5148d9670f8df8a3c9a4
(cd /tmp/vfox-tests && go build -o /tmp/vfox-test-runner .)
/tmp/vfox-test-runner plugin test .
/tmp/vfox-test-runner plugin run . PreInstall --input '{"version":"5.4.7"}' --json
```

`plugin run` permits real HTTP and shell commands. For installation verification,
use a disposable runner or VM. CI separately tests real installs with stable vfox
v1.0.12 on Linux, macOS and Windows, plus mise on Linux and macOS. It installs the
checked-out plugin, so the PR's actual contents are tested.

The `files` helper uses native `fs.copy`/`fs.remove` on vfox and keeps a fallback for
mise, which does not yet provide `fs`. mise's Lua 5.1 async functions cannot yield
through `pcall`, so its HTTP `try_get`/`try_download_file` APIs return errors directly.
Optional LuaRocks extraction uses a quoted `tar` fallback on mise; vfox uses its
native archive library. Both extract into a dedicated source directory.

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
