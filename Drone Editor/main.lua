-- Update main.lua to incorporate Fusion UI

-- Try to load Fusion UI first (preferred method)
local fusion_ui = nil
pcall(function() fusion_ui = require("lib.fusion_ui") end)

-- Then try to load regular UI as fallback
local ui = nil
if not fusion_ui then
    pcall(function() ui = require("lib.ui") end)
end

-- Main application function
local function main()
    -- Check if Fusion UI is available first
    local fusion_ui_available = false
    
    if fusion_ui then
        -- Try to initialize Fusion UI
        local success, result = pcall(function() return fusion_ui.initialize_ui() end)
        if success and result then
            fusion_ui_available = true
            logging.info("Fusion UI initialized successfully")
        else
            logging.warning("Fusion UI initialization failed, falling back to standard UI")
        end
    end
    
    -- Check if regular UI is available as fallback
    local ui_available = false
    
    if not fusion_ui_available and ui and ui.should_show_ui and type(ui.should_show_ui) == "function" then
        -- Try to check if UI should be shown
        local success, result = pcall(function() return ui.should_show_ui() end)
        if success and result then
            ui_available = true
            logging.info("Standard UI available")
        else
            logging.warning("Standard UI check failed")
        end
    end
    
    -- Initialize appropriate UI or fallback to console mode
    if fusion_ui_available and not args.console_mode then
        -- Try to initialize Fusion UI
        local status, result = pcall(function()
            if fusion_ui.show_main_window and type(fusion_ui.show_main_window) == "function" then
                return fusion_ui.show_main_window(resolve, project_obj, media_pool)
            end
            return false
        end)
        
        if not status then
            logging.error("Fusion UI error: " .. tostring(result))
            write_error("Fusion UI error: " .. tostring(result))
            -- Try regular UI as fallback
            ui_available = true
            logging.info("Falling back to standard UI due to Fusion UI error")
        else
            logging.info("Using Fusion UI for application interface")
        end
    end
    
    -- Try regular UI if Fusion UI failed or not available
    if not fusion_ui_available and ui_available and not args.console_mode then
        -- Try to initialize UI
        local status, result = pcall(function()
            if ui.show_main_window and type(ui.show_main_window) == "function" then
                return ui.show_main_window(resolve, project_obj, media_pool)
            end
            return false
        end)
        
        if not status then
            logging.error("UI error: " .. tostring(result))
            write_error("UI error: " .. tostring(result))
            -- Fall back to console mode
            logging.info("Falling back to console mode due to UI error")
            args.console_mode = true
        else
            logging.info("Using standard UI for application interface")
        end
    else
        -- Force console mode if no UI is available
        if not fusion_ui_available and not ui_available and not args.console_mode then
            logging.info("No UI available, using console mode")
            args.console_mode = true
        end
    end
    
    if args.console_mode then
        -- Command-line mode or script-only mode
        print("Drone Editor Lua initialized in console mode")
        print("Type 'help()' for available commands")
        
        -- Make core functionality available globally for console use
        _G.resolve = resolve
        _G.project = project_obj
        _G.media_pool = media_pool
        _G.import_media = function(file_paths) return mediapool.import_media(media_pool, file_paths) end
        _G.create_timeline = function(clips, name) return timeline.create_from_clips(project_obj, media_pool, clips, name) end
        _G.apply_transitions = function(timeline_obj) return timeline.apply_transitions(timeline_obj) end
        _G.apply_lut = function(lut_path) return color.apply_lut(project_obj, lut_path) end
        _G.save_project = function(filepath) return project.save(filepath, project_obj, media_pool) end
        _G.load_project = function(filepath) return project.load(filepath, project_obj, media_pool) end
        
        -- Get all clips from media pool
        _G.get_clips = function()
            local root_folder = media_pool:GetRootFolder()
            if root_folder then
                return root_folder:GetClipList()
            end
            return nil
        end
        
        -- Auto edit function
        _G.auto_edit = function()
            local clips = _G.get_clips()
            if not clips or #clips == 0 then
                print("No clips available")
                return false
            end
            
            local ai_simulation = require("ai_simulation")
            local new_timeline = _G.create_timeline(clips, "Auto Drone Edit")
            if not new_timeline then
                print("Failed to create timeline")
                return false
            end
            
            _G.apply_transitions(new_timeline)
            
            local lut_path = color.get_lut_path("Drone Aerial")
            if lut_path then
                _G.apply_lut(lut_path)
            end
            
            ai_simulation.enhance_audio(new_timeline, {
                normalize = true,
                noise_reduction = 0.7,
                eq = true,
                compression = 0.5
            })
            
            print("Auto-edit completed successfully")
            return true
        end
        
        -- Help function
        _G.help = function() 
            print("Available functions:")
            print("  import_media(file_paths) - Import media files")
            print("  get_clips() - Get all clips from media pool")
            print("  create_timeline(clips, name) - Create a timeline from clips")
            print("  apply_transitions(timeline) - Apply transitions between clips")
            print("  apply_lut(lut_path) - Apply a LUT to the current timeline")
            print("  save_project(filepath) - Save the current project to a file")
            print("  load_project(filepath) - Load a project from a file")
            print("  auto_edit() - Perform automatic edit with all clips")
        end
    end
end

-- Replace the existing main() function call with this updated version