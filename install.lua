-- Drone Editor Installation Script
-- Installs Drone Editor into DaVinci Resolve's Script menu

-- Get current script directory
local script_path = debug.getinfo(1).source:match("@?(.*[\\/])")
if not script_path then script_path = "./" end

-- Define output and error functions
local function output(msg)
    print(msg)
end

local function error_msg(msg)
    print("ERROR: " .. msg)
end

output("Drone Editor Installation")
output("=======================")
output("")

-- Determine OS
local os_name = "unknown"
if package.config:sub(1,1) == '\\' then
    os_name = "windows"
elseif os.execute('uname -s >/dev/null 2>&1') == 0 then
    local handle = io.popen('uname -s')
    if handle then
        local result = handle:read("*a")
        handle:close()
        result = result:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
        
        if result == "Darwin" then
            os_name = "macos"
        elseif result == "Linux" then
            os_name = "linux"
        end
    end
end

output("Detected operating system: " .. os_name)

-- Determine DaVinci Resolve Scripts directory
local resolve_scripts_dir = nil

if os_name == "windows" then
    resolve_scripts_dir = os.getenv("APPDATA") .. "\\Blackmagic Design\\DaVinci Resolve\\Support\\Scripts"
elseif os_name == "macos" then
    resolve_scripts_dir = os.getenv("HOME") .. "/Library/Application Support/Blackmagic Design/DaVinci Resolve/Support/Scripts"
elseif os_name == "linux" then
    resolve_scripts_dir = os.getenv("HOME") .. "/.local/share/DaVinciResolve/Support/Scripts"
else
    error_msg("Unsupported operating system")
    return
end

output("DaVinci Resolve Scripts directory: " .. resolve_scripts_dir)

-- Check if the Scripts directory exists
local scripts_dir_exists = false
local scripts_dir_handle = io.open(resolve_scripts_dir, "r")
if scripts_dir_handle then
    scripts_dir_handle:close()
    scripts_dir_exists = true
else
    output("DaVinci Resolve Scripts directory doesn't exist. Attempting to create it...")
    
    -- Try to create the directory
    if os_name == "windows" then
        os.execute('mkdir "' .. resolve_scripts_dir .. '" 2>nul')
    else
        os.execute('mkdir -p "' .. resolve_scripts_dir .. '" 2>/dev/null')
    end
    
    -- Check if creation was successful
    scripts_dir_handle = io.open(resolve_scripts_dir, "r")
    if scripts_dir_handle then
        scripts_dir_handle:close()
        scripts_dir_exists = true
        output("Created Scripts directory successfully")
    else
        error_msg("Failed to create DaVinci Resolve Scripts directory")
        return
    end
end

-- Create Drone Editor directory in Scripts folder
local drone_editor_dir = resolve_scripts_dir .. "/Drone Editor"
local drone_editor_dir_exists = false
local drone_editor_dir_handle = io.open(drone_editor_dir, "r")
if drone_editor_dir_handle then
    drone_editor_dir_handle:close()
    drone_editor_dir_exists = true
    output("Drone Editor directory already exists: " .. drone_editor_dir)
else
    output("Creating Drone Editor directory: " .. drone_editor_dir)
    
    -- Try to create the directory
    if os_name == "windows" then
        os.execute('mkdir "' .. drone_editor_dir .. '" 2>nul')
    else
        os.execute('mkdir -p "' .. drone_editor_dir .. '" 2>/dev/null')
    end
    
    -- Check if creation was successful
    drone_editor_dir_handle = io.open(drone_editor_dir, "r")
    if drone_editor_dir_handle then
        drone_editor_dir_handle:close()
        drone_editor_dir_exists = true
        output("Created Drone Editor directory successfully")
    else
        error_msg("Failed to create Drone Editor directory")
        return
    end
end

-- Create subdirectories
local subdirs = {"lib", "utils", "config", "effects", "logs"}
for _, subdir in ipairs(subdirs) do
    local dir_path = drone_editor_dir .. "/" .. subdir
    if os_name == "windows" then
        dir_path = dir_path:gsub("/", "\\")
        os.execute('mkdir "' .. dir_path .. '" 2>nul')
    else
        os.execute('mkdir -p "' .. dir_path .. '" 2>/dev/null')
    end
    output("Created directory: " .. subdir)
end

-- Copy script files
local function copy_file(src, dest)
    local src_file = io.open(src, "rb")
    if not src_file then
        error_msg("Failed to open source file: " .. src)
        return false
    end
    
    local content = src_file:read("*a")
    src_file:close()
    
    local dest_file = io.open(dest, "wb")
    if not dest_file then
        error_msg("Failed to create destination file: " .. dest)
        return false
    end
    
    dest_file:write(content)
    dest_file:close()
    
    return true
end

-- Files to copy (source relative to script_path, destination relative to drone_editor_dir)
local files_to_copy = {
    -- Main files
    {src = "DroneEditor.lua", dest = "../DroneEditor.lua"}, -- In Scripts folder, not in Drone Editor subfolder
    {src = "main.lua", dest = "main.lua"},
    {src = "init.lua", dest = "init.lua"},
    {src = "bootstrap.lua", dest = "bootstrap.lua"},
    
    -- Library files
    {src = "lib/fusion_ui.lua", dest = "lib/fusion_ui.lua"},
    {src = "lib/fusion_dialogs.lua", dest = "lib/fusion_dialogs.lua"},
    {src = "lib/resolve_connection.lua", dest = "lib/resolve_connection.lua"},
    {src = "lib/timeline.lua", dest = "lib/timeline.lua"},
    {src = "lib/mediapool.lua", dest = "lib/mediapool.lua"},
    {src = "lib/color.lua", dest = "lib/color.lua"},
    {src = "lib/fusion.lua", dest = "lib/fusion.lua"},
    {src = "lib/project.lua", dest = "lib/project.lua"},
    {src = "lib/ui.lua", dest = "lib/ui.lua"},
    
    -- Utility files
    {src = "utils/logging.lua", dest = "utils/logging.lua"},
    {src = "utils/ai_simulation.lua", dest = "utils/ai_simulation.lua"},
    {src = "utils/ai_bridge.lua", dest = "utils/ai_bridge.lua"},
    
    -- Configuration files
    {src = "config/settings.lua", dest = "config/settings.lua"},
    {src = "config/ai_settings.json", dest = "config/ai_settings.json"}
}

output("\nCopying files...")
local copy_count = 0
local error_count = 0

for _, file in ipairs(files_to_copy) do
    local src_path = script_path .. file.src
    local dest_path = drone_editor_dir .. "/" .. file.dest
    
    -- Special case for DroneEditor.lua which goes to Scripts folder
    if file.dest:find("^%.%./") then
        dest_path = resolve_scripts_dir .. "/" .. file.dest:sub(4)
    end
    
    -- Convert path separators for Windows
    if os_name == "windows" then
        src_path = src_path:gsub("/", "\\")
        dest_path = dest_path:gsub("/", "\\")
    end
    
    output("Copying " .. file.src .. " to " .. file.dest)
    if copy_file(src_path, dest_path) then
        copy_count = copy_count + 1
    else
        error_count = error_count + 1
    end
end

-- Create README file in the Drone Editor directory
local readme_content = [[
# Drone Editor for DaVinci Resolve

This is a Lua-based automation tool for editing drone footage in DaVinci Resolve.

## Features

- Automatic scene detection
- Color grading presets for drone footage
- Timeline automation
- Audio enhancement for drone recordings
- Project management

## Usage

1. Open DaVinci Resolve
2. Go to "Workspace" -> "Scripts" menu
3. Select "DroneEditor" from the list

## Support

For issues and feature requests, please contact the developers.
]]

local readme_file = io.open(drone_editor_dir .. "/README.md", "w")
if readme_file then
    readme_file:write(readme_content)
    readme_file:close()
    output("Created README.md file")
end

-- Final output
output("\nInstallation complete!")
output("  Files copied: " .. copy_count)
if error_count > 0 then
    output("  Errors: " .. error_count .. " (check the output above)")
end

output("\nTo use Drone Editor:")
output("1. Restart DaVinci Resolve if it's currently running")
output("2. Go to 'Workspace' -> 'Scripts' menu")
output("3. Select 'DroneEditor' from the list")
output("\nInstallation directory: " .. drone_editor_dir)