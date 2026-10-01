local windows = {}
local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function base64(value)
    local result = {}
    for index = 1, #value, 3 do
        local a, b, c = value:byte(index, index + 2)
        local number = a * 65536 + (b or 0) * 256 + (c or 0)
        local function character(shift)
            local position = math.floor(number / 2 ^ shift) % 64 + 1
            return alphabet:sub(position, position)
        end
        result[#result + 1] = character(18) .. character(12) ..
            (b and character(6) or "=") .. (c and character(0) or "=")
    end
    return table.concat(result)
end

function windows.path_expression(path)
    -- Encode UTF-8 paths separately so the PowerShell script itself stays ASCII.
    return "[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('" .. base64(path) .. "'))"
end

function windows.execute(script)
    -- GopherLua invokes cmd.exe through Go's argument quoting. Inline -Command
    -- quotes can become literals; EncodedCommand also prevents shell expansion.
    local utf16 = script:gsub(".", function(character) return character .. "\0" end)
    return os.execute("powershell -NoProfile -NonInteractive -EncodedCommand " .. base64(utf16))
end

return windows
