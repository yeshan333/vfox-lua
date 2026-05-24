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
        local pkg_meta = Utils.get_windows_luabinaries_package(lua_version)
        if pkg_meta == nil then
            error("LuaBinaries does not provide a Windows binary for version " ..
                lua_version .. ". Disable VFOX_LUA_WINDOWS_LUABINARIES or choose one of: " ..
                Utils.get_windows_luabinaries_versions_text() .. ".")
        end

        print("lua download url: " .. pkg_meta.url)
        -- LuaBinaries is distributed via SourceForge's mirror autoselect, which redirects to
        -- a rotating set of mirrors. vfox computed checksums sometimes hashed the redirect HTML
        -- instead of the archive bytes, so the integrity check was unreliable. Until upstream
        -- publishes signed checksums we can pin, the opt-in install relies on HTTPS only —
        -- documented as a trade-off in the README.
        return {
            version = lua_version,
            url = pkg_meta.url,
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
