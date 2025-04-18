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


return lua_utils
