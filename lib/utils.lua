local http = require("http")

local lua_utils = {}
local windows_luabinaries_packages = {
    ["5.5.0"] = {
        archive_name = "lua-5.5.0_Win64_bin.zip",
        relative_path = "5.5.0/Tools%20Executables/lua-5.5.0_Win64_bin.zip",
        executable_prefix = "lua55",
        wlua_prefix = "wlua55",
        dll_name = "lua55.dll",
    },
    ["5.4.8"] = {
        archive_name = "lua-5.4.8_Win64_bin.zip",
        relative_path = "5.4.8/Tools%20Executables/lua-5.4.8_Win64_bin.zip",
        executable_prefix = "lua54",
        wlua_prefix = "wlua54",
        dll_name = "lua54.dll",
    },
    ["5.3.6"] = {
        archive_name = "lua-5.3.6_Win64_bin.zip",
        relative_path = "5.3.6/Tools%20Executables/lua-5.3.6_Win64_bin.zip",
        executable_prefix = "lua53",
        wlua_prefix = "wlua53",
        dll_name = "lua53.dll",
    },
    ["5.2.4"] = {
        archive_name = "lua-5.2.4_Win64_bin.zip",
        relative_path = "5.2.4/Tools%20Executables/lua-5.2.4_Win64_bin.zip",
        executable_prefix = "lua52",
        wlua_prefix = "wlua52",
        dll_name = "lua52.dll",
    },
}

local versions_url = "https://fastly.jsdelivr.net/gh/yeshan333/vfox-lua@main/assets/versions.txt"

local function get_releases()
    -- mise exposes try_get because its Lua 5.1 async calls cannot yield through pcall.
    local resp, err = (http.try_get or http.get)({ url = versions_url })
    if err ~= nil or resp == nil then
        error("Failed to fetch Lua versions: " .. tostring(err))
    end
    if resp.status_code ~= 200 then
        error("Failed to fetch Lua versions: HTTP " .. tostring(resp.status_code))
    end
    local result = {}
    for line in string.gmatch(resp.body or "", "[^\r\n]+") do
        local version, checksum = string.match(line, "^%s*([%d%.]+),(%x+)%s*$")
        if version and #checksum == 64 then
            table.insert(result, { version = version, checksum = checksum })
        end
    end
    if #result == 0 then
        error("No valid Lua releases found in " .. versions_url)
    end
    return result
end

function lua_utils.get_lua_release_versions()
    return get_releases()
end

function lua_utils.get_version_info(lua_version)
    for _, release in ipairs(get_releases()) do
        if lua_version == release.version then
            return release.version, release.checksum
        end
    end
    return nil, nil
end

function lua_utils.use_windows_luabinaries()
    local flag = os.getenv("VFOX_LUA_WINDOWS_LUABINARIES")
    return flag ~= nil and flag ~= "" and flag ~= "0" and string.lower(flag) ~= "false"
end

function lua_utils.get_windows_luabinaries_versions()
    local versions = {}
    for version, _ in pairs(windows_luabinaries_packages) do
        table.insert(versions, version)
    end
    table.sort(versions, function(a, b)
        return a > b
    end)
    return versions
end

function lua_utils.get_windows_luabinaries_versions_text()
    return table.concat(lua_utils.get_windows_luabinaries_versions(), ", ")
end

function lua_utils.get_windows_luabinaries_package(lua_version)
    if RUNTIME.osType ~= "windows" then
        return nil
    end

    local pkg_meta = windows_luabinaries_packages[lua_version]
    if pkg_meta == nil then
        return nil
    end

    return {
        archive_name = pkg_meta.archive_name,
        executable_prefix = pkg_meta.executable_prefix,
        wlua_prefix = pkg_meta.wlua_prefix,
        dll_name = pkg_meta.dll_name,
        url = "https://sourceforge.net/projects/luabinaries/files/" ..
            pkg_meta.relative_path .. "/download?use_mirror=autoselect",
    }
end

function lua_utils.is_success_status(status)
    return status == true or status == 0
end

--- Check readline before compiling a source distribution.
function lua_utils.check_readline_installed()
    if RUNTIME.osType == "linux" then
        return lua_utils.is_success_status(os.execute("ldconfig -p 2>/dev/null | grep -q libreadline"))
    elseif RUNTIME.osType == "darwin" then
        return lua_utils.is_success_status(os.execute("brew list --versions readline >/dev/null 2>&1"))
    end
    return true
end

return lua_utils
