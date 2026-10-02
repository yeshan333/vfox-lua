describe("Lua installed through the plugin", function()
    local expected_version = assert(os.getenv("LUA_VERSION"), "LUA_VERSION must select the installed SDK")
    local temporary_files = {}

    local function temporary_file()
        local path = os.tmpname()
        temporary_files[#temporary_files + 1] = path
        return path
    end

    local function command_output(command)
        local process = assert(io.popen(command .. " 2>&1", "r"))
        local output = process:read("*a")
        local ok, reason, status = process:close()
        assert.is_true(ok == true or ok == 0, output .. " (" .. tostring(reason) .. ": " .. tostring(status) .. ")")
        return output
    end

    local function quote(path)
        return "'" .. path:gsub("'", "'\\''") .. "'"
    end

    after_each(function()
        for _, path in ipairs(temporary_files) do
            os.remove(path)
        end
        temporary_files = {}
    end)

    it("runs the requested Lua release with the matching interpreter API", function()
        assert.equal("Lua " .. expected_version:match("^%d+%.%d+"), _VERSION)
        local actual = command_output("lua -v"):match("Lua (%d+%.%d+%.%d+)")
        assert.equal(expected_version, actual)
    end)

    it("compiles a Lua source file with the installed luac and executes its bytecode", function()
        local source, bytecode = temporary_file(), temporary_file()
        local file = assert(io.open(source, "wb"))
        assert(file:write("local function multiply(a, b) return a * b end; return multiply(6, 7)\n"))
        assert(file:close())
        local compiler_version = command_output("luac -v"):match("Lua (%d+%.%d+%.%d+)")
        assert.equal(expected_version, compiler_version)
        command_output("luac -o " .. quote(bytecode) .. " " .. quote(source))
        assert.equal(42, assert(loadfile(bytecode))())
    end)

    it("loads a native LuaRocks module and reads attributes of a file created by Lua", function()
        local lfs = require("lfs")
        local path = temporary_file()
        local content = "installed Lua native module check"
        local file = assert(io.open(path, "wb"))
        assert(file:write(content))
        assert(file:close())
        assert.equal("file", lfs.attributes(path, "mode"))
        assert.equal(#content, lfs.attributes(path, "size"))
    end)
end)
