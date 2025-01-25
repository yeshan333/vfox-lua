--- Extension point, called after PreInstall, can perform additional operations,
--- such as file operations for the SDK installation directory or compile source code
--- Currently can be left unimplemented!
function PLUGIN:PostInstall(ctx)
    --- ctx.rootPath SDK installation directory
    -- use ENV OTP_COMPILE_ARGS to control compile behavior
    local sdkInfo = ctx.sdkInfo['lua']
    local path = sdkInfo.path
    print("lua installed path: " .. path)

    local install_cmd = "cd " .. path .. " && make all test " .. "INSTALL_TOP=" .. path .. "&& make install " .. "INSTALL_TOP=" .. path
    local status = os.execute(install_cmd)
    if status ~= 0 then
        error("lua install failed, please check the stdout for details.")
    end
end