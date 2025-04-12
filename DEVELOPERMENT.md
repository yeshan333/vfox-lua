# Developer Guide

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
