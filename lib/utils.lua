local http = require("http")

local lua_utils = {}
local windows_luabinaries_versions = { "5.5.0", "5.4.8", "5.3.6", "5.2.4" }

local versions_url = "https://fastly.jsdelivr.net/gh/yeshan333/vfox-lua@main/assets/versions.txt"

function lua_utils.get_lua_release_versions()
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

function lua_utils.get_version_info(lua_version)
    for _, release in ipairs(lua_utils.get_lua_release_versions()) do
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

function lua_utils.get_windows_luabinaries_versions_text()
    return table.concat(windows_luabinaries_versions, ", ")
end

function lua_utils.get_windows_luabinaries_package(lua_version)
    for _, version in ipairs(windows_luabinaries_versions) do
        if lua_version == version then
            local major, minor = string.match(version, "^(%d+)%.(%d+)")
            return {
                suffix = major .. minor,
                url = "https://sourceforge.net/projects/luabinaries/files/" .. version ..
                    "/Tools%20Executables/lua-" .. version .. "_Win64_bin.zip/download?use_mirror=autoselect",
            }
        end
    end
    return nil
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
