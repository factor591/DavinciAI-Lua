-- Fusion Native Dialogs
-- Specialized dialog system using Fusion's native UI components

local logging = require("logging")

local fusion_dialogs = {}

-- Store references to UI objects to prevent garbage collection
fusion_dialogs.ui_elements = {}

-- Initialize with Fusion object
-- @param fusion Fusion object
-- @return true if successful, false otherwise
function fusion_dialogs.init(fusion)
    if not fusion then
        logging.error("Cannot initialize Fusion dialogs: No Fusion object provided")
        return false
    end
    
    fusion_dialogs.fusion = fusion
    logging.info("Fusion dialog system initialized")
    return true
end

-- Check if the Fusion dialog system is available
-- @return Boolean indicating if the dialog system is available
function fusion_dialogs.is_available()
    return fusion_dialogs.fusion ~= nil
end

-- Create a dialog window using Fusion's built-in UI.Dialog class
-- @param title Dialog title
-- @param width Dialog width
-- @param height Dialog height
-- @param flags Optional dialog flags
-- @return Dialog object if successful, nil otherwise
function fusion_dialogs.create(title, width, height, flags)
    if not fusion_dialogs.is_available() then
        logging.error("Cannot create dialog: Fusion not available")
        return nil
    end
    
    title = title or "Drone Editor"
    width = width or 800
    height = height or 600
    flags = flags or {
        Modal = false,
        WindowTitle = title,
        Geometry = { Width = width, Height = height, },
        SourceCode = true, -- Allow Lua scripting
    }
    
    local dialog = nil
    local success, result = pcall(function()
        return fusion_dialogs.fusion.UIManager.DialogNew(flags)
    end)
    
    if success and result then
        dialog = result
        -- Store reference to prevent garbage collection
        table.insert(fusion_dialogs.ui_elements, dialog)
        return dialog
    else
        logging.error("Failed to create dialog: " .. tostring(result))
        return nil
    end
end

-- Add a button to a dialog
-- @param dialog Dialog object
-- @param text Button text
-- @param callback Function to call when button is clicked
-- @param position Table with x and y coordinates
-- @param size Table with width and height
-- @return Button object if successful, nil otherwise
function fusion_dialogs.add_button(dialog, text, callback, position, size)
    if not dialog then
        logging.error("Cannot add button: No dialog provided")
        return nil
    end
    
    text = text or "Button"
    position = position or { X = 0, Y = 0 }
    size = size or { Width = 100, Height = 30 }
    
    local button = nil
    local success, result = pcall(function()
        return dialog:AddButton(text, position, size)
    end)
    
    if success and result then
        button = result
        
        if callback and type(callback) == "function" then
            button.Clicked = callback
        end
        
        -- Store reference to prevent garbage collection
        table.insert(fusion_dialogs.ui_elements, button)
        return button
    else
        logging.error("Failed to add button: " .. tostring(result))
        return nil
    end
end

-- Add a label to a dialog
-- @param dialog Dialog object
-- @param text Label text
-- @param position Table with x and y coordinates
-- @param size Table with width and height
-- @return Label object if successful, nil otherwise
function fusion_dialogs.add_label(dialog, text, position, size)
    if not dialog then
        logging.error("Cannot add label: No dialog provided")
        return nil
    end
    
    text = text or ""
    position = position or { X = 0, Y = 0 }
    size = size or { Width = 200, Height = 30 }
    
    local label = nil
    local success, result = pcall(function()
        return dialog:AddLabel(text, position, size)
    end)
    
    if success and result then
        label = result
        -- Store reference to prevent garbage collection
        table.insert(fusion_dialogs.ui_elements, label)
        return label
    else
        logging.error("Failed to add label: " .. tostring(result))
        return nil
    end
end

-- Add a text edit field to a dialog
-- @param dialog Dialog object
-- @param text Initial text
-- @param position Table with x and y coordinates
-- @param size Table with width and height
-- @return Text edit object if successful, nil otherwise
function fusion_dialogs.add_text_edit(dialog, text, position, size)
    if not dialog then
        logging.error("Cannot add text edit: No dialog provided")
        return nil
    end
    
    text = text or ""
    position = position or { X = 0, Y = 0 }
    size = size or { Width = 200, Height = 30 }
    
    local text_edit = nil
    local success, result = pcall(function()
        return dialog:AddTextEdit(text, position, size)
    end)
    
    if success and result then
        text_edit = result
        -- Store reference to prevent garbage collection
        table.insert(fusion_dialogs.ui_elements, text_edit)
        return text_edit
    else
        logging.error("Failed to add text edit: " .. tostring(result))
        return nil
    end
end

-- Add a combo box (dropdown) to a dialog
-- @param dialog Dialog object
-- @param items Table of items to add to the combo box
-- @param position Table with x and y coordinates
-- @param size Table with width and height
-- @return Combo box object if successful, nil otherwise
function fusion_dialogs.add_combo_box(dialog, items, position, size)
    if not dialog then
        logging.error("Cannot add combo box: No dialog provided")
        return nil
    end
    
    items = items or {}
    position = position or { X = 0, Y = 0 }
    size = size or { Width = 200, Height = 30 }
    
    local combo_box = nil
    local success, result = pcall(function()
        return dialog:AddComboBox(items, position, size)
    end)
    
    if success and result then
        combo_box = result
        -- Store reference to prevent garbage collection
        table.insert(fusion_dialogs.ui_elements, combo_box)
        return combo_box
    else
        logging.error("Failed to add combo box: " .. tostring(result))
        return nil
    end
end

-- Add a slider to a dialog
-- @param dialog Dialog object
-- @param range Table with min and max values
-- @param value Initial value
-- @param position Table with x and y coordinates
-- @param size Table with width and height
-- @return Slider object if successful, nil otherwise
function fusion_dialogs.add_slider(dialog, range, value, position, size)
    if not dialog then
        logging.error("Cannot add slider: No dialog provided")
        return nil
    end
    
    range = range or { Min = 0, Max = 100 }
    value = value or range.Min
    position = position or { X = 0, Y = 0 }
    size = size or { Width = 200, Height = 30 }
    
    local slider = nil
    local success, result = pcall(function()
        return dialog:AddSlider(range, value, position, size)
    end)
    
    if success and result then
        slider = result
        -- Store reference to prevent garbage collection
        table.insert(fusion_dialogs.ui_elements, slider)
        return slider
    else
        logging.error("Failed to add slider: " .. tostring(result))
        return nil
    end
end

-- Show a file browser dialog
-- @param title Dialog title
-- @param start_dir Starting directory
-- @param filter File filter
-- @param multi_select Allow multiple file selection
-- @return Selected file path(s) or nil if canceled
function fusion_dialogs.browse_for_file(title, start_dir, filter, multi_select)
    if not fusion_dialogs.is_available() then
        logging.error("Cannot show file browser: Fusion not available")
        return nil
    end
    
    title = title or "Select File"
    start_dir = start_dir or ""
    filter = filter or "All Files (*.*)|*.*"
    multi_select = multi_select or false
    
    local files = nil
    local success, result = pcall(function()
        return fusion_dialogs.fusion:RequestFile(title, start_dir, filter, multi_select)
    end)
    
    if success then
        return result
    else
        logging.error("Failed to show file browser: " .. tostring(result))
        return nil
    end
end

-- Show a directory browser dialog
-- @param title Dialog title
-- @param start_dir Starting directory
-- @return Selected directory path or nil if canceled
function fusion_dialogs.browse_for_directory(title, start_dir)
    if not fusion_dialogs.is_available() then
        logging.error("Cannot show directory browser: Fusion not available")
        return nil
    end
    
    title = title or "Select Directory"
    start_dir = start_dir or ""
    
    local directory = nil
    local success, result = pcall(function()
        return fusion_dialogs.fusion:RequestDir(title, start_dir)
    end)
    
    if success then
        return result
    else
        logging.error("Failed to show directory browser: " .. tostring(result))
        return nil
    end
end

-- Show an alert message dialog
-- @param title Dialog title
-- @param message Message to display
-- @param buttons Table of button texts (default: "OK")
-- @return Selected button or nil if dialog failed
function fusion_dialogs.message_box(title, message, buttons)
    if not fusion_dialogs.is_available() then
        logging.error("Cannot show message box: Fusion not available")
        return nil
    end
    
    title = title or "Message"
    message = message or ""
    buttons = buttons or { "OK" }
    
    local result = nil
    local success, button = pcall(function()
        return fusion_dialogs.fusion:AskUser(title, {
            { "Text", Name = "Message", "Text", Label = "", Default = message },
        })
    end)
    
    if success then
        return true
    else
        logging.error("Failed to show message box: " .. tostring(button))
        return nil
    end
end

-- Show a custom form dialog with multiple controls
-- @param title Dialog title
-- @param controls Table of control definitions
-- @return Table of control values or nil if cancelled
function fusion_dialogs.show_custom_dialog(title, controls)
    if not fusion_dialogs.is_available() then
        logging.error("Cannot show custom dialog: Fusion not available")
        return nil
    end
    
    title = title or "Custom Dialog"
    controls = controls or {}
    
    local result = nil
    local success, values = pcall(function()
        return fusion_dialogs.fusion:AskUser(title, controls)
    end)
    
    if success then
        return values
    else
        logging.error("Failed to show custom dialog: " .. tostring(values))
        return nil
    end
end

-- Show a progress dialog and execute a task
-- @param title Dialog title
-- @param max_progress Maximum progress value
-- @param task_fn Function to execute with progress callback
-- @return Result of the task function or nil if canceled
function fusion_dialogs.show_progress_dialog(title, max_progress, task_fn)
    if not fusion_dialogs.is_available() then
        logging.error("Cannot show progress dialog: Fusion not available")
        return nil
    end
    
    title = title or "Progress"
    max_progress = max_progress or 100
    
    local progress = nil
    local success, progress_obj = pcall(function()
        return fusion_dialogs.fusion:ShowProgress(title, max_progress)
    end)
    
    if not success or not progress_obj then
        logging.error("Failed to create progress dialog: " .. tostring(progress_obj))
        return nil
    end
    
    progress = progress_obj
    
    -- Execute the task with progress reporting
    local result = nil
    success, result = pcall(function()
        return task_fn(function(value)
            progress:SetValue(value, max_progress)
            
            -- Check if the user canceled the operation
            if progress:IsAborted() then
                error("Progress dialog aborted by user")
            end
        end)
    end)
    
    -- Close the progress dialog
    progress:Close()
    
    if success then
        return result
    else
        logging.error("Task failed: " .. tostring(result))
        return nil
    end
end

-- Create and run the main Drone Editor window using Fusion's native UI
-- @param fusion Fusion object
-- @param resolve Resolve object
-- @param project_obj Project object
-- @param media_pool MediaPool object
-- @return true if successful, false otherwise
function fusion_dialogs.show_main_window(fusion, resolve, project_obj, media_pool)
    if not fusion_dialogs.is_available() and not fusion_dialogs.init(fusion) then
        logging.error("Cannot show main window: Fusion not available")
        return false
    end
    
    -- Create the main dialog
    local dialog = fusion_dialogs.create("Drone Editor", 800, 600)
    if not dialog then
        return false
    end
    
    -- Add title
    fusion_dialogs.add_label(dialog, "Drone Editor", { X = 10, Y = 10 }, { Width = 780, Height = 40 })
    
    -- Add toolbar buttons
    fusion_dialogs.add_button(dialog, "Import Media", function()
        local files = fusion_dialogs.browse_for_file("Import Media Files", "", "Video Files (*.mp4 *.mov *.avi)|*.mp4;*.mov;*.avi", true)
        if files and #files > 0 then
            fusion_dialogs.show_progress_dialog("Importing Media", 100, function(progress)
                local mediapool = require("lib.mediapool")
                
                for i = 1, 10 do
                    progress(i * 10)
                    -- Small delay to simulate work
                    os.execute("sleep 0.1")
                end
                
                local items = mediapool.import_media(media_pool, files)
                
                if items and #items > 0 then
                    fusion_dialogs.message_box("Import Complete", string.format("Successfully imported %d files", #items))
                    return true
                else
                    fusion_dialogs.message_box("Import Failed", "Failed to import media files")
                    return false
                end
            end)
        end
    }, { X = 10, Y = 60 }, { Width = 120, Height = 30 })
    
    fusion_dialogs.add_button(dialog, "Detect Scenes", function()
        local root_folder = media_pool:GetRootFolder()
        if not root_folder then
            fusion_dialogs.message_box("Error", "Cannot access media pool root folder")
            return
        end
        
        local clips = root_folder:GetClipList()
        if not clips or #clips == 0 then
            fusion_dialogs.message_box("No Clips", "No clips found in media pool")
            return
        end
        
        -- Create a custom confirmation dialog
        local confirm = fusion_dialogs.show_custom_dialog("Scene Detection", {
            { "Text", Name = "Message", ReadOnly = true, Default = "Analyze " .. #clips .. " clips for scene changes?" },
            { "Checkbox", Name = "Confirm", Text = "Yes, detect scenes", Default = 1 }
        })
        
        if not confirm or confirm.Confirm == 0 then
            return
        end
        
        fusion_dialogs.show_progress_dialog("Scene Detection", 100, function(progress)
            -- Run scene detection
            local ai_simulation = require("ai_simulation")
            local new_clips = ai_simulation.detect_scenes(clips, progress)
            
            if new_clips and #new_clips > 0 then
                -- Create a new timeline with detected scenes
                local timeline_module = require("lib.timeline")
                local current_timeline = project_obj:GetCurrentTimeline()
                
                if current_timeline then
                    -- Ask if we should update the existing timeline
                    local update = fusion_dialogs.show_custom_dialog("Update Timeline", {
                        { "Text", Name = "Message", ReadOnly = true, Default = "Update current timeline with detected scenes?" },
                        { "Checkbox", Name = "Update", Text = "Yes, update timeline", Default = 1 }
                    })
                    
                    if update and update.Update == 1 then
                        timeline_module.update_with_trimmed_clips(project_obj, media_pool, current_timeline, new_clips)
                        fusion_dialogs.message_box("Scene Detection Complete", string.format("Updated timeline with %d scenes", #new_clips))
                    end
                else
                    -- Create new timeline
                    local new_timeline = timeline_module.create_from_clips(project_obj, media_pool, clips, "Drone Scenes")
                    if new_timeline then
                        fusion_dialogs.message_box("Scene Detection Complete", string.format("Created new timeline with %d scenes", #new_clips))
                    else
                        fusion_dialogs.message_box("Timeline Creation Failed", "Failed to create new timeline")
                    end
                end
                
                return true
            else
                fusion_dialogs.message_box("Scene Detection Failed", "No scenes detected")
                return false
            end
        end)
    }, { X = 140, Y = 60 }, { Width = 120, Height = 30 })
    
    fusion_dialogs.add_button(dialog, "Color Grading", function()
        -- Create a custom color grading dialog
        local color_dialog = fusion_dialogs.show_custom_dialog("Color Grading", {
            { "Text", Name = "Title", ReadOnly = true, Default = "Select LUT or Color Preset:" },
            { "ComboBox", Name = "LutSelection", 
              Options = { "Default", "Cinematic", "Vintage", "Drone Aerial" }, Default = 1 },
            { "Slider", Name = "Intensity", 
              Integer = true, Default = 50, Min = 0, Max = 100, 
              Text = "Intensity" },
            { "Checkbox", Name = "ApplyLut", Text = "Apply LUT", Default = 1 },
            { "Checkbox", Name = "AutoColor", Text = "Auto Color Grade", Default = 0 }
        })
        
        if not color_dialog then
            return
        end
        
        -- Process the dialog results
        if color_dialog.ApplyLut == 1 then
            local color_module = require("lib.color")
            local lut_options = { "Default", "Cinematic", "Vintage", "Drone Aerial" }
            local lut_name = lut_options[color_dialog.LutSelection]
            local lut_path = color_module.get_lut_path(lut_name)
            
            if lut_path then
                if color_module.apply_lut(project_obj, lut_path) then
                    fusion_dialogs.message_box("Success", string.format("Applied %s LUT", lut_name))
                else
                    fusion_dialogs.message_box("Error", "Failed to apply LUT")
                end
            else
                fusion_dialogs.message_box("Error", string.format("LUT %s not found", lut_name))
            end
        end
        
        if color_dialog.AutoColor == 1 then
            fusion_dialogs.show_progress_dialog("Auto Color", 100, function(progress)
                local ai_simulation = require("ai_simulation")
                local intensity = color_dialog.Intensity / 100
                local success = ai_simulation.auto_color_grade(project_obj:GetCurrentTimeline(), intensity, progress)
                
                if success then
                    fusion_dialogs.message_box("Success", "Applied auto color grading")
                else
                    fusion_dialogs.message_box("Error", "Failed to apply auto color grading")
                end
                
                return success
            end)
        end
    }, { X = 270, Y = 60 }, { Width = 120, Height = 30 })
    
    fusion_dialogs.add_button(dialog, "Auto Edit", function()
        local root_folder = media_pool:GetRootFolder()
        if not root_folder then
            fusion_dialogs.message_box("Error", "Cannot access media pool root folder")
            return
        end
        
        local clips = root_folder:GetClipList()
        if not clips or #clips == 0 then
            fusion_dialogs.message_box("No Clips", "No clips found in media pool")
            return
        end
        
        -- Confirm auto edit operation
        local confirm = fusion_dialogs.show_custom_dialog("Auto Edit", {
            { "Text", Name = "Message", ReadOnly = true, Default = "Create an automatic edit with all clips?" },
            { "Checkbox", Name = "Confirm", Text = "Yes, create auto edit", Default = 1 }
        })
        
        if not confirm or confirm.Confirm == 0 then
            return
        end
        
        fusion_dialogs.show_progress_dialog("Auto Edit", 100, function(progress)
            -- Auto edit workflow
            local timeline_module = require("lib.timeline")
            local color_module = require("lib.color")
            local ai_simulation = require("ai_simulation")
            
            -- Step 1: Create timeline
            progress(10)
            local new_timeline = timeline_module.create_from_clips(project_obj, media_pool, clips, "Auto Drone Edit")
            if not new_timeline then
                fusion_dialogs.message_box("Error", "Failed to create timeline")
                return false
            end
            
            -- Step 2: Apply transitions
            progress(30)
            timeline_module.apply_transitions(new_timeline)
            
            -- Step 3: Color grading
            progress(50)
            local lut_path = color_module.get_lut_path("Drone Aerial")
            if lut_path then
                color_module.apply_lut(project_obj, lut_path)
            end
            
            -- Step 4: Audio enhancements
            progress(70)
            ai_simulation.enhance_audio(new_timeline, {
                normalize = true,
                noise_reduction = 0.7,
                eq = true,
                compression = 0.5
            }, function(p)
                progress(70 + p * 0.3)
            end)
            
            progress(100)
            fusion_dialogs.message_box("Auto Edit Complete", "Successfully created automatic edit")
            return true
        end)
    }, { X = 400, Y = 60 }, { Width = 120, Height = 30 })
    
    fusion_dialogs.add_button(dialog, "Project Settings", function()
        local project_module = require("lib.project")
        local summary = project_module.get_summary()
        
        -- Create project settings dialog
        local settings_dialog = fusion_dialogs.show_custom_dialog("Project Settings", {
            { "Text", Name = "Title", ReadOnly = true, Default = "Project Information" },
            { "Text", Name = "ProjectName", Label = "Project Name", Default = project_module.current.name },
            { "Text", Name = "Description", Label = "Description", Lines = 3, Default = project_module.current.description },
            { "Text", Name = "Created", Label = "Created", ReadOnly = true, Default = summary.created },
            { "Text", Name = "Modified", Label = "Modified", ReadOnly = true, Default = summary.modified },
            { "Text", Name = "TimelineName", Label = "Timeline", ReadOnly = true, Default = summary.timeline_name },
            { "Text", Name = "ClipCount", Label = "Clips", ReadOnly = true, Default = tostring(summary.clip_count) },
            { "Checkbox", Name = "NewProject", Text = "Create New Project", Default = 0 },
            { "Checkbox", Name = "SaveProject", Text = "Save Project", Default = 0 },
            { "Checkbox", Name = "LoadProject", Text = "Load Project", Default = 0 }
        })
        
        if not settings_dialog then
            return
        end
        
        -- Process dialog results
        if settings_dialog.NewProject == 1 then
            -- Create new project
            project_module.new(settings_dialog.ProjectName, settings_dialog.Description)
            fusion_dialogs.message_box("Project Created", "New project created successfully")
        end
        
        if settings_dialog.SaveProject == 1 then
            -- Save project
            local filepath = fusion_dialogs.browse_for_file(
                "Save Project",
                "",
                "Drone Project (*.droneproj)|*.droneproj",
                false
            )
            
            if filepath then
                -- Update project name and description from dialog
                project_module.current.name = settings_dialog.ProjectName
                project_module.current.description = settings_dialog.Description
                
                -- Save the project
                local success, err = project_module.save(filepath, project_obj, media_pool)
                
                if success then
                    fusion_dialogs.message_box("Project Saved", "Project saved successfully")
                else
                    fusion_dialogs.message_box("Save Error", "Failed to save project: " .. (err or "Unknown error"))
                end
            end
        end
        
        if settings_dialog.LoadProject == 1 then
            -- Load project
            local filepath = fusion_dialogs.browse_for_file(
                "Load Project",
                "",
                "Drone Project (*.droneproj)|*.droneproj",
                false
            )
            
            if filepath then
                local success, err = project_module.load(filepath, project_obj, media_pool)
                
                if success then
                    fusion_dialogs.message_box("Project Loaded", "Project loaded successfully")
                else
                    fusion_dialogs.message_box("Load Error", "Failed to load project: " .. (err or "Unknown error"))
                end
            end
        end
    }, { X = 530, Y = 60 }, { Width = 120, Height = 30 })
    
    fusion_dialogs.add_button(dialog, "Exit", function()
        dialog:Close()
    }, { X = 660, Y = 60 }, { Width = 120, Height = 30 })
    
    -- Add status label
    local status_label = fusion_dialogs.add_label(
        dialog, 
        "Current project: " .. project_obj:GetName(),
        { X = 10, Y = 560 },
        { Width = 780, Height = 30 }
    )
    
    -- Show the dialog (this will block until the dialog is closed)
    dialog:Show()
    
    return true
end

return fusion_dialogs