local test = require("vfox.test")
local status, transport_error, body = 200, nil, nil
local checksum = string.rep("a", 64)
local readline_status = 0
os.execute = function() return readline_status end
local plugin = test.load({
    os = "linux",
    http = function(request)
        assert(request.url:find("/assets/versions.txt", 1, true))
        if transport_error then return nil, transport_error end
        return { status_code = status, body = body }
    end,
})
local h = dofile(RUNTIME.pluginDirPath .. "/tests/helpers.lua")
h.scenario("Lua search excludes aggregate archives and invalid rows while retaining release order", function()
    body = "all," .. checksum .. "\r\n5.5.0," .. checksum .. "\r\ninvalid\n5.4.7," .. checksum .. "\n5.3.6,bad"
    local versions = plugin:Available({})
    assert(#versions == 2 and versions[1].version == "5.5.0" and versions[2].version == "5.4.7")
end)
h.scenario("Installing an exact Lua release returns the official source URL and SHA256", function()
    local archive = plugin:PreInstall({ version = "5.4.7" })
    assert(archive.url == "https://www.lua.org/ftp/lua-5.4.7.tar.gz")
    assert(archive.sha256 == checksum)
end)
h.scenario("Installing an unknown Lua release reports the missing version", function()
    h.raises("Version 9.9.9 not found", function() plugin:PreInstall({ version = "9.9.9" }) end)
end)
h.scenario("Installing Lua without readline reports the missing build dependency", function()
    readline_status = 1
    h.raises("readline library not found", function() plugin:PreInstall({ version = "5.4.7" }) end)
end)
h.scenario("Lua search reports an HTTP failure and recovers on the next successful request", function()
    status = 503
    h.raises("HTTP 503", function() plugin:Available({}) end)
    status = 200
    assert(#plugin:Available({}) == 2)
end)
h.scenario("Lua search reports a network timeout without indexing a missing response", function()
    transport_error = "request timed out"
    h.raises("request timed out", function() plugin:Available({}) end)
    transport_error = nil
end)
h.scenario("Lua search rejects an empty or malformed release listing", function()
    body = "<html>upstream error</html>"
    h.raises("No valid Lua releases", function() plugin:Available({}) end)
end)
