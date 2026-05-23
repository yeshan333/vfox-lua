local Utils = require("utils")

--- Returns some pre-installed information, such as version number, download address, local files, etc.
--- If checksum is provided, vfox will automatically check it for you.
--- @param ctx table
--- @field ctx.version string User-input version
--- @return table Version information
function PLUGIN:PreInstall(ctx)
    if not Utils.check_readline_installed() then
        print("Error: readline library not found. Please install readline development packages (e.g., libreadline-dev or readline-devel) and try again.\n")
        error("readline library not found, Lua will be compiled with readline ")
    end
    local lua_version = ctx.version
    local download_url

    if RUNTIME.osType == "windows" and Utils.use_windows_luabinaries() then
        local package = Utils.get_windows_luabinaries_package(lua_version)
        if package == nil then
            error("LuaBinaries does not provide a Windows binary for version " ..
                lua_version .. ". Disable VFOX_LUA_WINDOWS_LUABINARIES or choose one of: 5.5.0, 5.4.8, 5.3.6, 5.2.4.")
        end

        print("lua download url: " .. package.url)
        return {
            version = lua_version,
            url = package.url,
        }
    end

    local v, checksum = Utils.get_version_info(lua_version)
    if not v then
        error("Version " .. lua_version .. " not found in https://www.lua.org/ftp/.")
    end
    -- https://www.lua.org/ftp/lua-4.0.tar.gz
    -- https://www.lua.org/ftp/lua-all.tar.gz
    download_url = "https://www.lua.org/ftp/lua-" .. lua_version .. ".tar.gz"
    print("lua download url: " .. download_url)

    return {
        version = lua_version,
        url = download_url,
        sha256 = checksum
    }
end
