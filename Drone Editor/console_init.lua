-- console_init.lua - Direct console mode initialization

-- Get the script directory path
local script_path = "C:/Users/garre/AppData/Roaming/Blackmagic Design/DaVinci Resolve/Support/Scripts/Drone Editor/"

-- Add the script directories to the Lua path
package.path = script_path .. "?.lua;" .. 
               script_path .. "utils/?.lua;" .. 
               script_path .. "lib/?.lua;" .. 
               script_path .. "config/?.lua;" .. 
               package.path

-- Initialize logging
local logging = require("utils.logging")
logging.init(nil, "DEBUG")
logging.info("Initializing console mode")

-- Load core modules
local resolve_connection = require("lib.resolve_connection")
local mediapool = require("lib.mediapool")
local timeline = require("lib.timeline")
local color = require("lib.color")
local project = require("lib.project")

-- Get Resolve and project objects
local resolve = resolve_connection.init()
if not resolve then
    print("ERROR: Failed to connect to DaVinci Resolve")
    return
end

local project_manager = resolve:GetProjectManager()
local project_obj = project_manager:GetCurrentProject()
local media_pool = project_obj:GetMediaPool()

-- Make functions available globally
_G.resolve = resolve
_G.project = project_obj
_G.media_pool = media_pool
_G.import_media = function(file_paths) return mediapool.import_media(media_pool, file_paths) end
_G.create_timeline = function(clips, name) return timeline.create_from_clips(project_obj, media_pool, clips, name) end
_G.apply_transitions = function(timeline_obj) return timeline.apply_transitions(timeline_obj) end
_G.apply_lut = function(lut_path) return color.apply_lut(project_obj, lut_path) end

-- Help function
_G.help = function() 
    print("Available functions:")
    print("  import_media(file_paths) - Import media files")
    print("  create_timeline(clips, name) - Create a timeline from clips")
    print("  apply_transitions(timeline) - Apply transitions between clips")
    print("  apply_lut(lut_path) - Apply a LUT to the current timeline")
end

print("Drone Editor initialized in console mode")
print("Type 'help()' for available commands")