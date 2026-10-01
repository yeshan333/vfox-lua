local commands, command_status = {}, 0
local flag = "0"
os.execute = function(command)
    commands[#commands + 1] = command
    return command_status
end
local plugin = require("vfox.test").load({ os = "linux", env = { VFOX_LUA_LUAROCKS = "0" } })
os.getenv = function(key) if key == "VFOX_LUA_LUAROCKS" then return flag end end
local h = dofile(RUNTIME.pluginDirPath .. "/tests/helpers.lua")
local function install(version)
    plugin:PostInstall({ sdkInfo = { lua = { path = "/tmp/Lua build's directory", version = version } } })
end
h.scenario("Linux Lua 5.4 builds with readline and quotes an installation path containing spaces and apostrophes", function()
    install("5.4.7")
    assert(#commands == 1 and commands[1]:find("make linux-readline", 1, true))
    assert(commands[1]:find("'\\''", 1, true))
end)
h.scenario("Linux Lua 5.5 and later use the linux target without the removed readline target", function()
    for _, version in ipairs({ "5.5.0", "5.10.0", "6.0.0" }) do
        install(version)
        assert(commands[#commands]:find("make linux MYCFLAGS", 1, true))
    end
end)
h.scenario("LuaRocks opt-out accepts zero and case-insensitive false without downloads", function()
    for _, value in ipairs({ "0", "false", "FALSE" }) do
        flag = value
        local count = #commands
        install("5.4.7")
        assert(#commands == count + 1)
    end
end)
h.scenario("A failed Lua source build stops installation before LuaRocks runs", function()
    command_status = 2
    h.raises("Lua build/install failed", function() install("5.4.7") end)
end)
