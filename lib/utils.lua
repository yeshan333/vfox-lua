local http = require("http")

local lua_utils = {}

function lua_utils.get_lua_release_verions()
    local result = {}
    local resp, err = http.get({
        url = "https://fastly.jsdelivr.net/gh/yeshan333/vfox-lua@main/assets/versions.txt"
    })
    for line in string.gmatch(resp.body, '([^\n]+)') do
        local version, checksum = string.match(line, "([^,]+),([^,]+)")
        table.insert(result, {
            version = version,
            checksum = checksum
        })
    end

    return result
end

function lua_utils.get_version_info(lua_version)
    local resp, err = http.get({
        url = "https://fastly.jsdelivr.net/gh/yeshan333/vfox-lua@main/assets/versions.txt"
    })
    for line in string.gmatch(resp.body, '([^\n]+)') do
        local version, checksum = string.match(line, "([^,]+),([^,]+)")
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

function lua_utils.check_readline_installed()
    -- Check if the OS is Linux
    if package.config:sub(1,1) == '/' then
        -- On Linux, check for readline library
        -- Check for header files
        if os.execute("test -f /usr/include/readline/readline.h") == 0 or \
           os.execute("test -f /usr/local/include/readline/readline.h") == 0 or \
           os.execute("test -f /usr/include/readline.h") == 0 or \
           -- Check with ldconfig
           os.execute("ldconfig -p | grep -q libreadline") == 0 then
            return true
        else
            return false
        end
    else
        -- Not Linux, assume readline is available or not needed
        return true
    end
end

return lua_utils
