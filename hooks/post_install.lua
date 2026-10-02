local Utils = require("utils")
local Files = require("files")
local LuaRocks = require("luarocks")
local Windows = require("windows")

local function install_windows_binaries(path, version)
    local package = assert(Utils.get_windows_luabinaries_package(version), "LuaBinaries package metadata missing")
    local lua = path .. "/lua" .. package.suffix .. ".exe"
    assert(Files.exists(lua), "LuaBinaries executable not found at " .. lua)
    for _, name in ipairs({ "lua", "luac", "wlua" }) do
        local source = path .. "/" .. name .. package.suffix .. ".exe"
        if Files.exists(source) then
            Files.copy(source, path .. "/" .. name .. ".exe")
        end
    end
end

function PLUGIN:PostInstall(ctx)
    local sdk = ctx.sdkInfo.lua
    local path, version = sdk.path, sdk.version
    if RUNTIME.osType == "windows" then
        if Utils.use_windows_luabinaries() then
            install_windows_binaries(path, version)
        else
            assert(Utils.is_success_status(Windows.build(path)),
                "Lua build/install failed. Check the output above and ensure MSYS2 make and gcc are on PATH.")
        end
        return
    end

    local major, minor = string.match(version, "^(%d+)%.(%d+)")
    major, minor = tonumber(major), tonumber(minor)
    local target
    if RUNTIME.osType == "darwin" then
        target = "macosx"
    elseif RUNTIME.osType == "linux" then
        target = major == 5 and minor == 4 and "linux-readline" or "linux"
    else
        error("Unsupported platform: " .. RUNTIME.osType)
    end
    local quote = Files.shell_quote
    local command = "cd " .. quote(path) .. " && make " .. target ..
        " MYCFLAGS=-fPIC INSTALL_TOP=" .. quote(path) ..
        " && make install INSTALL_TOP=" .. quote(path)
    assert(Utils.is_success_status(os.execute(command)), "Lua build/install failed; check the output above.")

    local flag = string.lower(os.getenv("VFOX_LUA_LUAROCKS") or "")
    if major and major >= 5 and flag ~= "0" and flag ~= "false" then
        LuaRocks.install(path)
    end
end
