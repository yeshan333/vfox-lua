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


function PLUGIN:PostInstall(ctx)
    --- ctx.rootPath SDK installation directory
    -- use ENV OTP_COMPILE_ARGS to control compile behavior
    local sdkInfo = ctx.sdkInfo['lua']
    local path = sdkInfo.path
    local normalizedPath = string.gsub(path, "\\", "/")
    local lua_version = sdkInfo.version
    print(string.format("os type: %s, lua installed path: %s", RUNTIME.osType, path))

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
        if lua_version > "5.4" then
            local install_cmd1 = "cd " .. path .. " && make linux-readline " ..
                "INSTALL_TOP=" .. path
            local install_cmd2 = " && cd " .. path .. "&& make install " ..
                "INSTALL_TOP=" .. path
            status = os.execute(install_cmd1 .. install_cmd2)
        else
            local install_cmd1 = "cd " .. path .. " && make linux " ..
                "INSTALL_TOP=" .. path
            local install_cmd2 = " && cd " .. path .. "&& make install " ..
                "INSTALL_TOP=" .. path
            status = os.execute(install_cmd1 .. install_cmd2)
        end
    elseif RUNTIME.osType == "darwin" then
        local install_cmd1 = "cd " .. path .. " && make macosx " ..
            "INSTALL_TOP=" .. path
        local install_cmd2 = " && cd " .. path .. "&& make install " ..
            "INSTALL_TOP=" .. path
        status = os.execute(install_cmd1 .. install_cmd2)
    else
        error("Unsupported platform: " .. RUNTIME.osType)
    end
    if status ~= 0 then
        error("lua install failed, please check the stdout for details.")
    end
end
