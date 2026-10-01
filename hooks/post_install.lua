local Utils = require("utils")
local Files = require("files")
local LuaRocks = require("luarocks")
local Windows = require("windows")

local function check_windows_build_tools()
    for _, tool in ipairs({ "make.exe", "gcc.exe" }) do
        local status = Windows.execute("$ErrorActionPreference = 'Stop'; Get-Command " .. tool .. " -ErrorAction Stop")
        if not Utils.is_success_status(status) then
            error("Build tool " .. tool .. " not found. Install make and gcc via MSYS2 and add them to PATH.")
        end
    end
end

local function install_windows_binaries(path, version)
    local package = assert(Utils.get_windows_luabinaries_package(version), "LuaBinaries package metadata missing")
    local lua = path .. "/" .. package.executable_prefix .. ".exe"
    assert(Files.exists(lua), "LuaBinaries executable not found at " .. lua)
    Files.copy(lua, path .. "/lua.exe")
    for _, alias in ipairs({
        { source = "luac" .. string.sub(package.executable_prefix, 4), name = "luac" },
        { source = package.wlua_prefix, name = "wlua" },
    }) do
        local source = path .. "/" .. alias.source .. ".exe"
        if Files.exists(source) then
            Files.copy(source, path .. "/" .. alias.name .. ".exe")
        end
    end
end

function PLUGIN:PostInstall(ctx)
    local sdk = ctx.sdkInfo.lua
    local path, version = sdk.path, sdk.version
    if RUNTIME.osType == "windows" and Utils.use_windows_luabinaries() then
        install_windows_binaries(path, version)
        return
    end

    local command
    if RUNTIME.osType == "windows" then
        check_windows_build_tools()
        local script = "$ErrorActionPreference = 'Stop'; $prefix = " .. Windows.path_expression(path) .. "; " ..
            "Set-Location -LiteralPath $prefix; make mingw; " ..
            "if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; " ..
            "make install ('INSTALL_TOP=' + $prefix.Replace('\\', '/')); " ..
            "if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; " ..
            "Copy-Item -Path 'src\\*.dll' -Destination 'bin' -Force"
        assert(Utils.is_success_status(Windows.execute(script)), "Lua build/install failed; check the output above.")
        return
    elseif RUNTIME.osType == "linux" or RUNTIME.osType == "darwin" then
        local major, minor = string.match(version, "^(%d+)%.(%d+)")
        major, minor = tonumber(major), tonumber(minor)
        local target = "linux"
        if RUNTIME.osType == "darwin" then
            target = "macosx"
        elseif major == 5 and minor == 4 then
            target = "linux-readline"
        end
        local quote = Files.shell_quote
        command = "cd " .. quote(path) .. " && make " .. target ..
            " MYCFLAGS=-fPIC INSTALL_TOP=" .. quote(path) ..
            " && make install INSTALL_TOP=" .. quote(path)
    else
        error("Unsupported platform: " .. RUNTIME.osType)
    end
    assert(Utils.is_success_status(os.execute(command)), "Lua build/install failed; check the output above.")

    local flag = string.lower(os.getenv("VFOX_LUA_LUAROCKS") or "")
    local major = tonumber(string.match(version, "^(%d+)"))
    if RUNTIME.osType ~= "windows" and major and major >= 5 and flag ~= "0" and flag ~= "false" then
        LuaRocks.install(path)
    end
end
