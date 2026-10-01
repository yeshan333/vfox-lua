local plugin = require("vfox.test").load({ os = "windows" })
local h = dofile(RUNTIME.pluginDirPath .. "/tests/helpers.lua")
local present = {}
io.open = function(path)
    if present[path] then return { close = function() end } end
end
local function envs()
    return plugin:EnvKeys({ path = "C:/Lua", sdkInfo = { lua = { path = "C:/Lua", version = "5.4.8" } } })
end
h.scenario("Compiled Lua adds only its bin directory when LuaRocks is absent", function()
    local items = envs()
    assert(#items == 1 and items[1].key == "PATH" and items[1].value == "C:/Lua/bin")
end)
h.scenario("Prebuilt Windows Lua activates from its executable layout without an install-time flag", function()
    present["C:/Lua/lua.exe"] = true
    local items = envs()
    assert(items[1].key == "PATH" and items[1].value == "C:/Lua")
end)
h.scenario("An incomplete LuaRocks directory does not add broken executables or LUA_INIT", function()
    present["C:/Lua/luarocks/bin"] = true
    assert(#envs() == 2)
end)
h.scenario("Installed LuaRocks adds its executable path and Lua 5.4 module search paths", function()
    present["C:/Lua/luarocks/bin/luarocks"] = true
    local items = envs()
    assert(#items == 4 and items[3].value == "C:/Lua/luarocks/bin" and items[4].key == "LUA_INIT")
    assert(items[4].value:find("C:/Lua/luarocks/share/lua/5.4/?.lua", 1, true))
end)
h.scenario("LuaRocks activation produces valid Lua code when its directory contains apostrophes", function()
    present["C:/Lua's directory/luarocks/bin/luarocks"] = true
    local items = plugin:EnvKeys({ path = "C:\\Lua's directory", sdkInfo = { lua = { version = "5.4.8" } } })
    assert(items[1].value == "C:/Lua's directory/bin")
    assert(loadstring(items[#items].value))
end)
