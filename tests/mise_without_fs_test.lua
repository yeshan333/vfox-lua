require("vfox.test").load()
local h = dofile(RUNTIME.pluginDirPath .. "/tests/helpers.lua")
local native_require = require
require = function(name)
    if name == "fs" then error("module fs not found") end
    return native_require(name)
end
-- Load a fresh compatibility helper with the same missing-module behavior as mise.
local files = dofile(RUNTIME.pluginDirPath .. "/lib/files.lua")
require = native_require
h.scenario("mise without the fs module still copies binary contents to an executable alias", function()
    local source, destination = os.tmpname(), os.tmpname()
    local file = assert(io.open(source, "wb"))
    file:write("lua\0binary\255contents")
    file:close()
    local ok, err = pcall(function()
        files.copy(source, destination)
        local copy = assert(io.open(destination, "rb"))
        assert(copy:read("*a") == "lua\0binary\255contents")
        copy:close()
    end)
    os.remove(source)
    os.remove(destination)
    assert(ok, err)
end)
h.scenario("mise without fs cleans only the exact LuaRocks artifact path with shell quoting", function()
    local command
    os.execute = function(value) command = value return 0 end
    files.remove("/tmp/Lua build's directory/luarocks-source")
    assert(command == "rm -rf -- '/tmp/Lua build'\\''s directory/luarocks-source'")
end)
