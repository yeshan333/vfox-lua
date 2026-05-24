local Utils = require("utils")

--- Extension point, called after PreInstall, can perform additional operations,
--- such as file operations for the SDK installation directory or compile source code
function CheckBuildTools(osType)
    if osType == "windows" then
        local makeCheckCmd = "powershell -Command Get-Command make.exe"
        local makeInstalledStatus = os.execute(makeCheckCmd)
        local gccCheckCmd = "powershell -Command Get-Command gcc.exe"
        local gccInstalledStatus = os.execute(gccCheckCmd)
        if makeInstalledStatus ~= 0 or gccInstalledStatus ~= 0 then
            error([[
Build tools are not installed. Please install make and gcc. Suggestion steps:
1. Install MSYS2 from https://www.msys2.org/
2. Keep default Start Menu shortcuts
3. Run these commands in MSYS2 terminal:
pacman -Syu
pacman -S make
pacman -S --needed base-devel mingw-w64-x86_64-toolchain

Make sure make.exe and gcc.exe are in the System $env:PATH in PowerShell.
            ]])
        end
    end
end

local function copy_file(src, dst)
    local input = io.open(src, "rb")
    if input == nil then
        return false
    end
    local content = input:read("*a")
    input:close()

    local output = io.open(dst, "wb")
    if output == nil then
        return false
    end
    output:write(content)
    output:close()
    return true
end

local function file_exists(path)
    local f = io.open(path, "rb")
    if f == nil then
        return false
    end
    f:close()
    return true
end

local function InstallWindowsLuaBinaries(path, lua_version)
    local pkg_meta = Utils.get_windows_luabinaries_package(lua_version)
    if pkg_meta == nil then
        error("LuaBinaries package metadata missing for version " .. lua_version)
    end

    -- LuaBinaries archives expand executables (lua54.exe, luac54.exe, ...) into the install
    -- root next to the DLL. We add aliases (lua.exe, luac.exe, wlua.exe) in the same folder
    -- so users can invoke them by their canonical names. env_keys.lua already prepends the
    -- install root to PATH, so a separate bin/ directory isn't needed.
    local lua_exe = path .. "\\" .. pkg_meta.executable_prefix .. ".exe"
    if not file_exists(lua_exe) then
        error("LuaBinaries executable not found at " .. lua_exe)
    end

    local copies = {
        { src = lua_exe, dst = path .. "\\lua.exe" },
    }

    local luac_prefix = "luac" .. string.sub(pkg_meta.executable_prefix, 4)
    local luac_exe = path .. "\\" .. luac_prefix .. ".exe"
    if file_exists(luac_exe) then
        table.insert(copies, { src = luac_exe, dst = path .. "\\luac.exe" })
    end

    local wlua_exe = path .. "\\" .. pkg_meta.wlua_prefix .. ".exe"
    if file_exists(wlua_exe) then
        table.insert(copies, { src = wlua_exe, dst = path .. "\\wlua.exe" })
    end

    for _, item in ipairs(copies) do
        if not copy_file(item.src, item.dst) then
            error("failed to copy " .. item.src .. " to " .. item.dst)
        end
    end
end


function PLUGIN:PostInstall(ctx)
    --- ctx.rootPath SDK installation directory
    -- use ENV OTP_COMPILE_ARGS to control compile behavior
    local sdkInfo = ctx.sdkInfo['lua']
    local path = sdkInfo.path
    local normalizedPath = string.gsub(path, "\\", "/")
    local lua_version = sdkInfo.version
    print(string.format("os type: %s, lua installed path: %s", RUNTIME.osType, path))

    if RUNTIME.osType == "windows" and Utils.use_windows_luabinaries() then
        InstallWindowsLuaBinaries(path, lua_version)
        return
    end

    CheckBuildTools(RUNTIME.osType)
    -- TODO: support install luajit
    local status
    if RUNTIME.osType == "windows" then
        local cmd = string.format(
            "powershell -Command cd %s; make mingw;",
            path
        )
        status = os.execute(cmd)

        cmd = string.format(
            "powershell -Command cd %s; make install INSTALL_TOP=%s; Copy-Item -Path \"src\\*.dll\" -Destination \"bin\" -Force;",
            path,
            normalizedPath
        )
        status = os.execute(cmd)
    elseif RUNTIME.osType == "linux" then
        local make_target
        if lua_version >= "5.5" then
            -- Lua 5.5+ removed 'linux-readline' target; 'linux' now includes readline via dynamic loading
            make_target = "linux"
        elseif lua_version > "5.4" then
            make_target = "linux-readline"
        else
            make_target = "linux"
        end
        local install_cmd1 = "cd " .. path .. " && make " .. make_target ..
            " MYCFLAGS=-fPIC INSTALL_TOP=" .. path
        local install_cmd2 = " && cd " .. path .. "&& make install " ..
            "INSTALL_TOP=" .. path
        status = os.execute(install_cmd1 .. install_cmd2)
    elseif RUNTIME.osType == "darwin" then
        local install_cmd1 = "cd " .. path .. " && make macosx " ..
            "MYCFLAGS=-fPIC INSTALL_TOP=" .. path
        local install_cmd2 = " && cd " .. path .. "&& make install " ..
            "INSTALL_TOP=" .. path
        status = os.execute(install_cmd1 .. install_cmd2)
    else
        error("Unsupported platform: " .. RUNTIME.osType)
    end
    if status ~= 0 then
        error("lua install failed, please check the stdout for details.")
    end

    -- Install LuaRocks (Unix only, Lua 5.x only, opt-in via VFOX_LUA_LUAROCKS=1)
    local luarocks_flag = os.getenv("VFOX_LUA_LUAROCKS")
    local major = tonumber(string.match(lua_version, "^(%d+)"))
    if luarocks_flag and luarocks_flag ~= "0" and luarocks_flag ~= "false"
        and major and major >= 5 and RUNTIME.osType ~= "windows" then
        local http = require("http")
        local json = require("json")

        local luarocksVersion = "3.11.1"

        local resp, err = http.get({
            url = "https://api.github.com/repos/luarocks/luarocks/releases/latest",
        })

        if err == nil and resp.status_code == 200 then
            local data = json.decode(resp.body)
            if data ~= nil and type(data) == "table" then
                local tag = data["tag_name"]
                if tag then
                    luarocksVersion = string.gsub(tag, "^v", "")
                end
            end
        end

        local luarocksUrl = "https://github.com/luarocks/luarocks/archive/refs/tags/v" .. luarocksVersion .. ".tar.gz"
        local luarocksArchive = path .. "/luarocks.tar.gz"

        local downloadCmd = string.format("curl -sL '%s' -o '%s'", luarocksUrl, luarocksArchive)
        status = os.execute(downloadCmd)
        if status ~= 0 and status ~= true then
            return
        end

        local extractCmd = string.format("cd '%s' && tar xzf luarocks.tar.gz", path)
        status = os.execute(extractCmd)
        if status ~= 0 and status ~= true then
            return
        end

        local luarocksDir = path .. "/luarocks-" .. luarocksVersion
        local configureCmd = string.format(
            "cd '%s' && ./configure --with-lua='%s' --with-lua-include='%s/include' --with-lua-lib='%s/lib' --prefix='%s/luarocks' 2>/dev/null",
            luarocksDir,
            path,
            path,
            path,
            path
        )
        status = os.execute(configureCmd)
        if status ~= 0 and status ~= true then
            os.execute(string.format("rm -rf '%s/luarocks.tar.gz' '%s/luarocks-'*", path, path))
            return
        end

        local bootstrapCmd = string.format("cd '%s' && make bootstrap 2>&1", luarocksDir)
        os.execute(bootstrapCmd)

        os.execute(string.format("rm -rf '%s/luarocks.tar.gz' '%s/luarocks-'*", path, path))
    end
end
