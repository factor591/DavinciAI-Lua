-- DroneEditor.lua
-- Entry point for DaVinci Resolve Script Menu
-- Place this file in DaVinci Resolve's Scripts folder

-- Get the script directory path
local script_path = debug.getinfo(1).source:match("@?(.*[\\/])")
if not script_path then script_path = "./" end

-- Add paths to find modules
package.path = script_path .. "?.lua;" .. 
               script_path .. "lib/?.lua;" .. 
               script_path .. "utils/?.lua;" .. 
               script_path .. "config/?.lua;" .. 
               package.path

-- Basic error logging function (for early initialization)
local function write_error(message)
    local docs_dir = os.getenv("USERPROFILE") or os.getenv("HOME") or "."
    if package.config:sub(1,1) == '\\' then -- Windows
        docs_dir = docs_dir .. "\\Documents\\DroneEditor\\logs"
    else -- macOS/Linux
        docs_dir = docs_dir .. "/Documents/DroneEditor/logs"
    end
    
    -- Try to create directory
    if package.config:sub(1,1) == '\\' then -- Windows
        os.execute('mkdir "' .. docs_dir .. '" 2>nul')
    else -- macOS/Linux
        os.execute('mkdir -p "' .. docs_dir .. '" 2>/dev/null')
    end
    
    local error_file_path = docs_dir .. "/drone_editor_error.log"
    local error_file = io.open(error_file_path, "a")
    if error_file then
        error_file:write(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. message .. "\n")
        error_file:close()
    end
end

-- Entry point function for DaVinci Resolve script menu
function DroneEditor()
    -- Safe require function
    local function safe_require(module_name)
        local success, module = pcall(require, module_name)
        if not success then
            write_error("Failed to load module '" .. module_name .. "': " .. tostring(module))
            return nil
        end
        return module
    end
    
    -- Try to load logging module first
    local logging = safe_require("utils.logging")
    if not logging then
        -- Fallback: try a different path
        logging = safe_require("logging")
        if not logging then
            print("ERROR: Critical logging module could not be loaded")
            write_error("Critical: Logging module could not be loaded")
            return
        end
    end
    
    -- Initialize logging
    local success, err = pcall(function()
        logging.init(nil, "DEBUG")
    end)
    
    if not success then
        write_error("Failed to initialize logging: " .. tostring(err))
        print("ERROR: Failed to initialize logging")
        return
    end
    
    logging.info("Starting Drone Editor from DaVinci Resolve script menu")
    
    -- Load core modules
    local resolve_connection = safe_require("lib.resolve_connection")
    if not resolve_connection then return end
    
    local mediapool = safe_require("lib.mediapool")
    if not mediapool then return end
    
    local timeline = safe_require("lib.timeline")
    if not timeline then return end
    
    local color = safe_require("lib.color")
    if not color then return end
    
    local fusion = safe_require("lib.fusion")
    if not fusion then return end
    
    local project = safe_require("lib.project")
    if not project then return end
    
    -- Load AI simulation
    local ai_simulation = safe_require("utils.ai_simulation")
    if not ai_simulation then return end
    
    -- Try to load Fusion UI 
    local fusion_ui = safe_require("lib.fusion_ui")
    local ui_module = nil
    
    if not fusion_ui then
        logging.warning("Fusion UI module not available, falling back to standard UI")
        ui_module = safe_require("lib.ui")
        
        if not ui_module then
            logging.warning("Standard UI not available either, will use console mode")
        end
    end
    
    -- Get Resolve API access via DaVinci Resolve context
    local resolve = nil
    
    -- In DaVinci Resolve script menu context, we can directly access the API
    if not resolve and fusion then
        -- We're being run from Fusion
        logging.info("Accessing Resolve through Fusion script context")
        local status, result = pcall(function() return fusion:GetResolve() end)
        if status and result then
            resolve = result
        else
            logging.error("Failed to get Resolve through Fusion: " .. tostring(result))
        end
    end
    
    -- Try to get through bmd global
    if not resolve and bmd then
        logging.info("Accessing Resolve through bmd global")
        local status, result = pcall(function()
            local fusion_app = bmd.scriptapp("Fusion")
            if fusion_app then
                return fusion_app:GetResolve()
            end
            return nil
        end)
        
        if status and result then
            resolve = result
        else
            logging.error("Failed to get Resolve through bmd global: " .. tostring(result))
        end
    end
    
    -- If still no Resolve access, use resolve_connection
    if not resolve then
        logging.info("Using resolve_connection to access Resolve API")
        local status, result = pcall(function() return resolve_connection.init() end)
        if status and result then
            resolve = result
        else
            logging.critical("Failed to connect to DaVinci Resolve: " .. tostring(result))
            print("ERROR: Failed to connect to DaVinci Resolve")
            return
        end
    end
    
    if not resolve then
        logging.critical("Failed to establish any connection to DaVinci Resolve")
        print("ERROR: Unable to connect to DaVinci Resolve")
        return
    end
    
    logging.info("Successfully connected to DaVinci Resolve")
    
    -- Log environment information
    local os_name = resolve_connection.get_os_info()
    local resolve_version = resolve_connection.get_resolve_version(resolve)
    logging.info("Operating System: " .. os_name)
    logging.info("DaVinci Resolve Version: " .. resolve_version)
    
    -- Get current project
    local project_manager = resolve:GetProjectManager()
    local project_obj = project_manager:GetCurrentProject()
    
    if not project_obj then
        logging.warning("No current project, creating a new one")
        project_obj = project_manager:CreateProject("Drone Edit Project")
        
        if not project_obj then
            logging.critical("Failed to create a new project")
            print("ERROR: Failed to create a new project")
            return
        end
    end
    
    logging.info("Current Project: " .. project_obj:GetName())
    
    -- Get media pool
    local media_pool = project_obj:GetMediaPool()
    if not media_pool then
        logging.critical("Failed to access Media Pool")
        print("ERROR: Failed to access Media Pool")
        return
    end
    
    -- Create a new Drone Edit project
    project.new("Drone Edit - " .. os.date("%Y-%m-%d %H:%M"), "Automated drone footage edit")
    
    -- Launch UI based on what's available
    if fusion_ui then
        -- Initialize Fusion UI
        local success, result = pcall(function()
            if fusion then
                return fusion_ui.init(fusion)
            else
                local fusion_app = bmd.scriptapp("Fusion")
                return fusion_ui.init(fusion_app)
            end
        end)
        
        if success and result then
            logging.info("Launching Drone Editor with Fusion UI")
            fusion_ui.show_main_window(resolve, project_obj, media_pool)
        else
            logging.error("Failed to initialize Fusion UI: " .. tostring(result))
            
            -- Try standard UI as fallback
            if ui_module then
                logging.info("Falling back to standard UI")
                ui_module.show_main_window(resolve, project_obj, media_pool)
            else
                -- Launch console mode
                print("Drone Editor initialized in console mode")
                print("Type 'help()' for available commands")
                
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
            end
        end
    elseif ui_module then
        -- Use standard UI
        logging.info("Launching Drone Editor with standard UI")
        ui_module.show_main_window(resolve, project_obj, media_pool)
    else
        -- Fall back to console mode
        print("Drone Editor initialized in console mode")
        print("Type 'help()' for available commands")
        
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
    end
    
    logging.info("Drone Editor launched successfully")
end

-- Call the function directly when loading through Script menu
DroneEditor()