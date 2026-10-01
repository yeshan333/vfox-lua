local commands, status = {}, 0
local function execute(command)
    commands[#commands + 1] = command
    if command:find("Set-Location", 1, true) then return status end
    return 0
end
local plugin = require("vfox.test").load({ os = "windows" })
local windows = require("windows")
windows.execute = execute
local h = dofile(RUNTIME.pluginDirPath .. "/tests/helpers.lua")
local function install()
    plugin:PostInstall({ sdkInfo = { lua = { path = "C:/Lua build's directory", version = "5.4.7" } } })
end
h.scenario("Windows source installation preserves its directory and stops after a failed make command", function()
    install()
    assert(#commands == 3)
    assert(commands[3]:find(windows.path_expression("C:/Lua build's directory"), 1, true))
    assert(commands[3]:find("Set-Location -LiteralPath $prefix", 1, true))
    local _, guards = commands[3]:gsub("if %(%$LASTEXITCODE", "")
    assert(guards == 2)
    status = 1
    h.raises("Lua build/install failed", install)
end)
h.scenario("Windows source installation reports a missing compiler before invoking make", function()
    windows.execute = function(command) if command:find("gcc.exe", 1, true) then return 1 end return 0 end
    h.raises("gcc.exe not found", install)
end)
