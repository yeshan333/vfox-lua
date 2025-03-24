--- Extension point, called after PreInstall, can perform additional operations,
--- such as file operations for the SDK installation directory or compile source code
--- Currently can be left unimplemented!
---


function PLUGIN:PostInstall(ctx)
    --- ctx.rootPath SDK installation directory
    -- use ENV OTP_COMPILE_ARGS to control compile behavior
    local sdkInfo = ctx.sdkInfo['lua']
    local path = sdkInfo.path
    local makeFileNormalizedPath = string.gsub(path, "\\", "/")
  
    local lua_version = sdkInfo.version
    print("lua installed path: " .. path)
  
    -- TODO: support install luajit
    local status
    if RUNTIME.osType == "windows" then
      local start_menu_paths = {
        os.getenv("ProgramData") .. "\\Microsoft\\Windows\\Start Menu\\Programs\\MSYS2\\MSYS2 MSYS.lnk",
        os.getenv("APPDATA") .. "\\Microsoft\\Windows\\Start Menu\\Programs\\MSYS2\\MSYS2 MSYS.lnk"
      }
  
      local shortcut_path
      for _, spath in ipairs(start_menu_paths) do
        -- Construct the PowerShell command
        local command = 'powershell -Command (New-Object -ComObject WScript.Shell).CreateShortcut(\'' .. spath .. '\').TargetPath'
        
        -- Execute the command and capture stdout
        local handle = io.popen(command)
        local output = handle:read("*a")  -- Read all output
        handle:close()
        
        -- Trim whitespace and check for non-empty output
        output = output:gsub("%s+", "")
        if output ~= "" then
          shortcut_path = output
          break
        end
      end
      
  
      -- Validate MSYS2 path
      if shortcut_path == "" then
        error([[
          MSYS2 not found. Required steps:
          1. Install MSYS2 from https://www.msys2.org/
          2. Keep default Start Menu shortcuts
          3. Run these commands in MSYS2 terminal:
          pacman -Syu
          pacman -S  make
          pacman -S --needed base-devel mingw-w64-x86_64-toolchain
        ]])
      end
  
      local msys_root = shortcut_path:match("(.*)msys2%.exe")
      if not msys_root then
        error("MSYS2 path not found")
      end
  
      -- Verify critical files exist
      local toolchain = "mingw"
      local toolTable = {
        ["mingw"] = "mingw64"
      }
      local toolChainSubFolder = toolTable[toolchain]
  
      
      local cmd = string.format(
        -- "powershell -Command cd %s\\src; $env:PATH = '%s;%s;%s'; Write-Output ''; $env:PATH; Write-Output ''",
        "powershell -Command cd %s\\src; $env:PATH = '%s;%s;%s'; make %s  INSTALL_TOP=%s;",
        path,
        msys_root .. "usr\\bin",
        msys_root .. toolChainSubFolder .. "\\bin",
        os.getenv("PATH"),
        toolchain,
        makeFileNormalizedPath
      ) 
      status = os.execute(cmd)
  
      local source = debug.getinfo(1, "S").source
      -- Handle both @-prefixed and raw paths
      local script_path = source:match("^@?(.*[\\/])") or ".\\"
      -- Normalize to Windows paths
      script_path = script_path:gsub("/", "\\"):gsub("\\+$", "") .. "\\"
      local input_path = script_path .. "..\\assets\\Makefile.windows"
      local output_path =  path .. "\\Makefile" 
      -- print("\n"..input_path .. " -> " .. output_path .. "\n")
      local input = io.open(input_path, "r")
      local output = io.open(output_path, "w")    
      output:write(input:read("*a"))
      input:close()
      output:close()    
  
      local cmd = string.format(
        "powershell -Command cd %s; $env:PATH = '%s;%s;%s'; make install INSTALL_TOP=%s ;",
        path,
        msys_root .. "usr\\bin",
        msys_root .. toolChainSubFolder .. "\\bin",
        os.getenv("PATH"),
        makeFileNormalizedPath
      ) 
      status = os.execute(cmd)    
  
    elseif RUNTIME.osType == "linux" then
      -- BUG: need lua5.4
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
  