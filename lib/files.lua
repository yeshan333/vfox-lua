local files = {}
local has_fs, fs = pcall(require, "fs")

function files.exists(path)
    local file = io.open(path, "rb")
    if file == nil then
        return false
    end
    file:close()
    return true
end

function files.shell_quote(value)
    return "'" .. string.gsub(value, "'", "'\\''") .. "'"
end

function files.copy(source, destination)
    if has_fs then
        return fs.copy(source, destination)
    end
    -- mise does not expose vfox's fs module yet.
    local input = assert(io.open(source, "rb"))
    local content = input:read("*a")
    input:close()
    local output = assert(io.open(destination, "wb"))
    assert(output:write(content))
    assert(output:close())
end

-- Only used for Unix LuaRocks build artifacts, at exact paths without globs.
function files.remove(path)
    if has_fs then
        return fs.remove(path)
    end
    local status = os.execute("rm -rf -- " .. files.shell_quote(path))
    assert(status == 0 or status == true, "failed to remove " .. path)
end

return files
