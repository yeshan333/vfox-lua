require("vfox.test").load({ os = "linux" })
local h = dofile(RUNTIME.pluginDirPath .. "/tests/helpers.lua")
local http, fs = require("http"), require("fs")
local path = os.tmpname()
os.remove(path)
fs.copy(RUNTIME.pluginDirPath .. "/tests/fixtures/sdk", path)
local download_state, commands = { succeeds = true }, {}
http.try_get = function() return { status_code = 200, body = '{"tag_name":"v3.11.1"}' } end
http.get = function() error("mise must use the error-returning HTTP API") end
http.try_download_file = function(_, archive)
    if not download_state.succeeds then return nil, "network timeout" end
    local file = assert(io.open(archive, "wb"))
    file:write("fixture archive")
    file:close()
    return true, nil
end
http.download_file = function() error("mise must use the error-returning download API") end
os.execute = function(command)
    commands[#commands + 1] = command
    if command:find("tar xzf", 1, true) then
        fs.copy(RUNTIME.pluginDirPath .. "/tests/fixtures/luarocks", path .. "/luarocks-source")
    end
    return 0
end
local native_require = require
require = function(name)
    if name == "vfox.archiver" then error("module vfox.archiver not found") end
    return native_require(name)
end
local rocks = dofile(RUNTIME.pluginDirPath .. "/lib/luarocks.lua")
require = native_require
local ok, err = pcall(function()
    h.scenario("mise installs LuaRocks using error-returning HTTP APIs and its tar compatibility path", function()
        rocks.install(path)
        assert(#commands == 3 and commands[1]:find("--strip-components=1", 1, true))
        assert(io.open(path .. "/luarocks-source/configure", "rb") == nil)
    end)
    h.scenario("mise preserves Lua after a LuaRocks download timeout without starting extraction", function()
        download_state.succeeds = false
        local count = #commands
        rocks.install(path)
        assert(#commands == count, "commands=" .. #commands .. ", before=" .. count .. ", last=" .. tostring(commands[#commands]))
        local marker = assert(io.open(path .. "/placeholder.txt", "r"))
        marker:close()
    end)
end)
fs.remove(path)
assert(ok, err)
