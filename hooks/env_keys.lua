local Files = require("files")

function PLUGIN:EnvKeys(ctx)
    local installDir = string.gsub(ctx.path, "\\", "/")
    local shortVersion = string.match(ctx.sdkInfo.lua.version, "^(%d+%.%d+)")
    local envs = {
        { key = "PATH", value = installDir .. "/bin" },
    }

    -- Detect the installed layout: the LuaBinaries opt-in may no longer be set on activation.
    if RUNTIME.osType == "windows" and Files.exists(installDir .. "/lua.exe") then
        table.insert(envs, 1, { key = "PATH", value = installDir })
    end

    local luarocksBin = installDir .. "/luarocks/bin"
    if not Files.exists(luarocksBin .. "/luarocks") then
        return envs
    end
    table.insert(envs, { key = "PATH", value = luarocksBin })

    if shortVersion then
        local paths, cpaths = {}, {}
        for _, prefix in ipairs({ installDir, installDir .. "/luarocks" }) do
            local share = prefix .. "/share/lua/" .. shortVersion
            table.insert(paths, share .. "/?.lua")
            table.insert(paths, share .. "/?/init.lua")
            table.insert(cpaths, prefix .. "/lib/lua/" .. shortVersion .. "/?.so")
        end
        table.insert(envs, {
            key = "LUA_INIT",
            value = "package.path = package.path .. " .. string.format("%q", ";" .. table.concat(paths, ";")) ..
                "\npackage.cpath = package.cpath .. " .. string.format("%q", ";" .. table.concat(cpaths, ";")),
        })
    end
    return envs
end
