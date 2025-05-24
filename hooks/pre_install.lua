local Utils = require("utils")

--- Returns some pre-installed information, such as version number, download address, local files, etc.
--- If checksum is provided, vfox will automatically check it for you.
--- @param ctx table
--- @field ctx.version string User-input version
--- @return table Version information
function PLUGIN:PreInstall(ctx)
    if not Utils.check_readline_installed() then
        print("Error: readline library not found. Please install readline development packages (e.g., libreadline-dev or readline-devel) and try again.")
        error("readline library not found")
    end
    local lua_version = ctx.version
    local download_url

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