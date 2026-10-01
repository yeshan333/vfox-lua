local api_status, api_body, archive_status = 200, '{"tag_name":"v3.11.1"}', 200
local commands, downloads, build_status = {}, {}, 0
local bootstrap_status, install_path = 0, nil
os.execute = function(command)
    commands[#commands + 1] = command
    if command:find("./configure", 1, true) then return build_status end
    if command:find("make bootstrap", 1, true) then
        if bootstrap_status ~= 0 then
            require("fs").copy(RUNTIME.pluginDirPath .. "/tests/fixtures/sdk", install_path .. "/luarocks")
        end
        return bootstrap_status
    end
    return 0
end
local plugin = require("vfox.test").load({
    os = "linux",
    http = function(request)
        if request.url:find("/releases/latest", 1, true) then return { status_code = api_status, body = api_body } end
        downloads[#downloads + 1] = request.url
        local fixture = assert(io.open(RUNTIME.pluginDirPath .. "/tests/fixtures/luarocks.tar.gz", "rb"))
        local body = fixture:read("*a")
        fixture:close()
        return { status_code = archive_status, body = body }
    end,
})
local fs = require("fs")
local h = dofile(RUNTIME.pluginDirPath .. "/tests/helpers.lua")
local function install()
    local path = os.tmpname()
    os.remove(path)
    path = path .. " Lua\'s sdk"
    fs.copy(RUNTIME.pluginDirPath .. "/tests/fixtures/sdk", path)
    install_path = path
    local ok, err = pcall(function()
        plugin:PostInstall({ sdkInfo = { lua = { path = path, version = "5.4.7" } } })
        assert(io.open(path .. "/luarocks.tar.gz", "rb") == nil)
        assert(io.open(path .. "/luarocks-source/configure", "rb") == nil)
        assert(io.open(path .. "/luarocks/placeholder.txt", "rb") == nil)
    end)
    fs.remove(path)
    assert(ok, err)
end
h.scenario("Default Lua installation downloads and extracts LuaRocks with native libraries and cleans build artifacts", function()
    install()
    assert(#commands == 3 and #downloads == 1)
    assert(commands[2]:find("/luarocks-source' && ./configure", 1, true))
    assert(commands[3]:find("make bootstrap", 1, true))
end)
h.scenario("LuaRocks API failure falls back to version 3.11.1 and still builds", function()
    api_status = 503
    install()
    assert(downloads[#downloads]:find("v3.11.1.tar.gz", 1, true))
    api_status = 200
end)
h.scenario("An invalid LuaRocks release tag uses the fallback instead of constructing an unsafe URL", function()
    api_body = '{"tag_name":"v3.11.1;unexpected"}'
    install()
    assert(downloads[#downloads]:find("v3.11.1.tar.gz", 1, true))
end)
h.scenario("A failed LuaRocks download preserves Lua and removes any downloaded artifact", function()
    archive_status = 404
    local count = #commands
    install()
    assert(#commands == count + 1)
    archive_status = 200
end)
h.scenario("A failed LuaRocks build preserves Lua and cleans the extracted sources", function()
    build_status = 1
    install()
end)
h.scenario("A failed LuaRocks bootstrap removes its incomplete installation and preserves Lua", function()
    build_status, bootstrap_status = 0, 1
    install()
end)
