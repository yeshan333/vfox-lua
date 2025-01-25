--- Extension point, called after PreInstall, can perform additional operations,
--- such as file operations for the SDK installation directory or compile source code
--- Currently can be left unimplemented!
function PLUGIN:PostInstall(ctx)
    --- ctx.rootPath SDK installation directory
    -- use ENV OTP_COMPILE_ARGS to control compile behavior
    local sdkInfo = ctx.sdkInfo['lua']
    local path = sdkInfo.path
    local lua_version = sdkInfo.version
    print("lua installed path: " .. path)

    -- TODO: support install luajit
    local status
    if RUNTIME.osType == "linux" then
        -- BUG: need lua5.4
        if lua_version > "5.4" then
            local install_cmd1 = "cd " .. path .. " && make linux-readline " .. "INSTALL_TOP=" .. path
            local install_cmd2 = " && cd " .. path .. "&& make install " .. "INSTALL_TOP=" .. path
            status = os.execute(install_cmd1 .. install_cmd2)
        else
            local install_cmd1 = "cd " .. path .. " && make linux " .. "INSTALL_TOP=" .. path
            local install_cmd2 = " && cd " .. path .. "&& make install " .. "INSTALL_TOP=" .. path
            status = os.execute(install_cmd1 .. install_cmd2)
        end
    elseif RUNTIME.osType == "darwin" then
        local install_cmd1 = "cd " .. path .. " && make macosx " .. "INSTALL_TOP=" .. path
        local install_cmd2 = " && cd " .. path .. "&& make install " .. "INSTALL_TOP=" .. path
        status = os.execute(install_cmd1 .. install_cmd2)
    else
        error("Unsupported platform: " .. RUNTIME.osType)
    end
    if status ~= 0 then
        error("lua install failed, please check the stdout for details.")
    end
end