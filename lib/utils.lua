local http = require("http")

local lua_utils = {}
local windows_luabinaries_packages = {
    ["5.5.0"] = {
        archive_name = "lua-5.5.0_Win64_bin.zip",
        relative_path = "5.5.0/Tools%20Executables/lua-5.5.0_Win64_bin.zip",
        executable_prefix = "lua55",
        wlua_prefix = "wlua55",
        dll_name = "lua55.dll",
        sha256 = "7825cb261d0dc61cb0e1511d451ceaf10bf72d2bba1855bfd3350add190e0024",
    },
    ["5.4.8"] = {
        archive_name = "lua-5.4.8_Win64_bin.zip",
        relative_path = "5.4.8/Tools%20Executables/lua-5.4.8_Win64_bin.zip",
        executable_prefix = "lua54",
        wlua_prefix = "wlua54",
        dll_name = "lua54.dll",
        sha256 = "9c5d151bfe2b62bd685d88bd1963c17dd5ea2fed37defcda7c02ee6e226bcc39",
    },
    ["5.3.6"] = {
        archive_name = "lua-5.3.6_Win64_bin.zip",
        relative_path = "5.3.6/Tools%20Executables/lua-5.3.6_Win64_bin.zip",
        executable_prefix = "lua53",
        wlua_prefix = "wlua53",
        dll_name = "lua53.dll",
        sha256 = "5150a30db5b62956d1bca4c2f3e5d1e08c00e398d8c902f0572b09f014012287",
    },
    ["5.2.4"] = {
        archive_name = "lua-5.2.4_Win64_bin.zip",
        relative_path = "5.2.4/Tools%20Executables/lua-5.2.4_Win64_bin.zip",
        executable_prefix = "lua52",
        wlua_prefix = "wlua52",
        dll_name = "lua52.dll",
        sha256 = "6cc8153640b5c1fc4632f18dadaa8696c5b7aef85e885245280d7e31011549d9",
    },
}

local function parse_version_line(line)
    return string.match(line, "([^,]+),([^,]+)")
end

local function is_lua_release_version(version)
    return string.match(version, "^%d") ~= nil
end

function lua_utils.get_lua_release_verions()
    local result = {}
    local resp, err = http.get({
        url = "https://fastly.jsdelivr.net/gh/yeshan333/vfox-lua@main/assets/versions.txt"
    })
    for line in string.gmatch(resp.body, '([^\n]+)') do
        local version, checksum = parse_version_line(line)
        if version and checksum and is_lua_release_version(version) then
            table.insert(result, {
                version = version,
                checksum = checksum
            })
        end
    end

    return result
end

function lua_utils.get_version_info(lua_version)
    local resp, err = http.get({
        url = "https://fastly.jsdelivr.net/gh/yeshan333/vfox-lua@main/assets/versions.txt"
    })
    for line in string.gmatch(resp.body, '([^\n]+)') do
        local version, checksum = parse_version_line(line)
        if lua_version == version then
            return version, checksum
        end
    end

    return nil, nil
end

function lua_utils.use_windows_luabinaries()
    local flag = os.getenv("VFOX_LUA_WINDOWS_LUABINARIES")
    return flag ~= nil and flag ~= "" and flag ~= "0" and flag ~= "false"
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
        sha256 = pkg_meta.sha256,
        url = "https://sourceforge.net/projects/luabinaries/files/" ..
            pkg_meta.relative_path .. "/download?use_mirror=autoselect",
    }
end

function lua_utils.is_success_status(status)
    return status == true or status == 0
end

function lua_utils.is_dir(path)
    local status = os.execute("[ -d " .. path .. " ]")
    return status == 0
end

--- Checks if the readline library is installed on the system.
-- This function supports Linux and macOS platforms.
-- On Linux, it uses `ldconfig` to check for the library.
-- On macOS, it uses `brew list` to verify installation.
-- For other platforms, it assumes readline is available or not required.
-- @return boolean `true` if readline is installed, `false` otherwise.
function lua_utils.check_readline_installed()
    if RUNTIME.osType == "Linux" then
        -- Check with ldconfig to determine if readline is missing
        if not os.execute("ldconfig -p | grep -q libreadline") then
            -- Readline library is missing
            return false
        end
        return true
    elseif RUNTIME.osType == "darwin" then
        if not os.execute("brew list readline") then
            return false
        end
    end
    -- Not Linux or MacOS, assume readline is available or not needed
    return true
end

return lua_utils
