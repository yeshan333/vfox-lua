local plugin = require("vfox.test").load({
    os = "windows", arch = "amd64",
    env = { VFOX_LUA_WINDOWS_LUABINARIES = "1" },
})
local h = dofile(RUNTIME.pluginDirPath .. "/tests/helpers.lua")
h.scenario("Windows prebuilt installation selects the LuaBinaries archive without build tools or network lookup", function()
    local archive = plugin:PreInstall({ version = "5.4.8" })
    assert(archive.url:find("lua-5.4.8_Win64_bin.zip", 1, true))
    assert(archive.sha256 == "" or archive.sha256 == nil)
end)
h.scenario("Windows prebuilt installation rejects a version absent from LuaBinaries", function()
    h.raises("does not provide a Windows binary", function() plugin:PreInstall({ version = "5.4.7" }) end)
end)
