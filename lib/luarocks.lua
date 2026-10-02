local http = require("http")
local json = require("json")
local has_archiver, archiver = pcall(require, "vfox.archiver")
local Files = require("files")
local Utils = require("utils")

local luarocks = {}
-- Keep the fallback compatible with every Lua version in the E2E matrix.
local fallback_version = "3.13.0"

local function release_version()
    local resp, err = (http.try_get or http.get)({
        url = "https://api.github.com/repos/luarocks/luarocks/releases/latest",
    })
    if err == nil and resp and resp.status_code == 200 then
        local decoded, data = pcall(json.decode, resp.body)
        if decoded and type(data) == "table" and type(data.tag_name) == "string" then
            local version = string.match(data.tag_name, "^v(%d+%.%d+%.%d+)$")
            if version then
                return version
            end
        end
    end
    print("Warning: could not resolve the latest LuaRocks release; using " .. fallback_version .. ".")
    return fallback_version
end

local function cleanup(path)
    local removed, err = pcall(Files.remove, path)
    if not removed then
        print("Warning: could not clean up " .. path .. ": " .. tostring(err))
    end
end

function luarocks.install(path)
    local version = release_version()
    local archive = path .. "/luarocks.tar.gz"
    local source = path .. "/luarocks-source"
    local prefix = path .. "/luarocks"
    local extract_started, bootstrap_started = false, false
    local quote = Files.shell_quote
    local request = {
        url = "https://github.com/luarocks/luarocks/archive/refs/tags/v" .. version .. ".tar.gz",
    }
    local download_err
    if http.try_download_file then
        local downloaded, err = http.try_download_file(request, archive)
        if not downloaded then
            download_err = err or "LuaRocks download failed"
        end
    else
        download_err = http.download_file(request, archive)
    end
    local ok, err = false, download_err
    if download_err == nil then
        ok, err = pcall(function()
            extract_started = true
            if has_archiver then
                local extract_err = archiver.decompress(archive, source)
                assert(extract_err == nil, extract_err)
            else
                -- mise's async archiver also cannot yield inside pcall. Use a quoted
                -- tar command here so optional extraction failures still preserve Lua.
                local command = "mkdir -p " .. quote(source) .. " && tar xzf " .. quote(archive) ..
                    " -C " .. quote(source) .. " --strip-components=1"
                assert(Utils.is_success_status(os.execute(command)), "LuaRocks extraction failed")
            end
            assert(Files.exists(source .. "/configure"), "LuaRocks configure script not found")
            local configure = "cd " .. quote(source) .. " && ./configure" ..
                " --with-lua=" .. quote(path) ..
                " --with-lua-include=" .. quote(path .. "/include") ..
                " --with-lua-lib=" .. quote(path .. "/lib") ..
                " --prefix=" .. quote(prefix)
            assert(Utils.is_success_status(os.execute(configure)), "LuaRocks configure failed")
            bootstrap_started = true
            assert(Utils.is_success_status(os.execute("cd " .. quote(source) .. " && make bootstrap")),
                "LuaRocks bootstrap failed")
        end)
    end

    -- LuaRocks is optional: leave a working Lua installation on failure.
    if not ok then
        print("Warning: LuaRocks installation skipped: " .. tostring(err))
    end
    if Files.exists(archive) then
        cleanup(archive)
    end
    if extract_started then
        cleanup(source)
    end
    if not ok and bootstrap_started then
        cleanup(prefix)
    end
end

return luarocks
