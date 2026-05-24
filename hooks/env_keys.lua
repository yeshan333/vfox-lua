--- Each SDK may have different environment variable configurations.
--- This allows plugins to define custom environment variables (including PATH settings)
--- @param ctx table Context information
--- @field ctx.path string SDK installation directory
function PLUGIN:EnvKeys(ctx)
    local sdkInfo = ctx.sdkInfo["lua"]
    local version = sdkInfo.version
    local installDir = ctx.path

    local shortVersion = string.match(version, "^(%d+%.%d+)")

    local envs = {
        {
            key = "PATH",
            value = installDir .. "/bin",
        },
    }

    -- LuaBinaries installs place lua.exe in the install root next to the DLL; MSYS2 source
    -- builds only populate bin/. Detect the LuaBinaries layout by probing the file so PATH
    -- stays correct on `vfox use` even when VFOX_LUA_WINDOWS_LUABINARIES (an install-time
    -- opt-in) is no longer exported in the activation shell.
    if RUNTIME.osType == "windows" then
        local rootLua = io.open(installDir .. "/lua.exe", "r")
        if rootLua ~= nil then
            rootLua:close()
            table.insert(envs, 1, {
                key = "PATH",
                value = installDir,
            })
        end
    end

    local luarocksBin = installDir .. "/luarocks/bin"
    local f = io.open(luarocksBin, "r")
    if f ~= nil then
        f:close()
        table.insert(envs, {
            key = "PATH",
            value = luarocksBin,
        })

        if shortVersion then
            local packagePath = string.format(
                "package.path = package.path .. ';%s/share/lua/%s/?.lua;%s/share/lua/%s/?/init.lua;%s/luarocks/share/lua/%s/?.lua;%s/luarocks/share/lua/%s/?/init.lua'",
                installDir,
                shortVersion,
                installDir,
                shortVersion,
                installDir,
                shortVersion,
                installDir,
                shortVersion
            )
            local packageCpath = string.format(
                "package.cpath = package.cpath .. ';%s/lib/lua/%s/?.so;%s/luarocks/lib/lua/%s/?.so'",
                installDir,
                shortVersion,
                installDir,
                shortVersion
            )

            table.insert(envs, {
                key = "LUA_INIT",
                value = packagePath .. "\n" .. packageCpath,
            })
        end
    end

    return envs
end
