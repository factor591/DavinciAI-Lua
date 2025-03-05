-- bootstrap.lua - Entry point for running in DaVinci Resolve
-- This sets up the correct paths and loads the main script

-- Get the script directory path
local script_path = debug.getinfo(1).source:match("@?(.*[\\/])")
if not script_path then script_path = "./" end

-- Add the script directories to the Lua path
package.path = script_path .. "?.lua;" .. 
               script_path .. "utils/?.lua;" .. 
               script_path .. "lib/?.lua;" .. 
               script_path .. "config/?.lua;" .. 
               package.path

-- Show a message
print("DavinciAI: Setting up environment from " .. script_path)

-- Force console mode
_G.arg = {"--console"}

-- Load and run the main script
local status, error_msg = pcall(function()
    dofile(script_path .. "main.lua")
end)

if not status then
    print("ERROR running main.lua: " .. tostring(error_msg))
end