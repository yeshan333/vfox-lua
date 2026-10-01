require("vfox.test").load({ os = "windows" })
local windows = require("windows")
local h = dofile(RUNTIME.pluginDirPath .. "/tests/helpers.lua")
h.scenario("Windows commands preserve PowerShell variables through cmd.exe argument quoting", function()
    local command
    os.execute = function(value) command = value return 0 end
    assert(windows.execute("exit $LASTEXITCODE") == 0)
    assert(command == "powershell -NoProfile -NonInteractive -EncodedCommand " ..
        "ZQB4AGkAdAAgACQATABBAFMAVABFAFgASQBUAEMATwBEAEUA")
end)
h.scenario("Windows install paths preserve UTF-8 and shell-sensitive characters", function()
    assert(windows.path_expression("C:/Lua 测试's $directory") ==
        "[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('QzovTHVhIOa1i+ivlSdzICRkaXJlY3Rvcnk='))")
end)
