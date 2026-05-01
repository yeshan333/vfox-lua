local http = require("http")

local lua_utils = {}

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
