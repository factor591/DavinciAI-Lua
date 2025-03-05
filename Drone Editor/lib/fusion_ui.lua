-- Fusion UI Module
-- Handles UI components using DaVinci Resolve's Fusion UI framework

local logging = require("logging")
local settings = require("settings")

local fusion_ui = {}

-- Store references to UI objects to prevent garbage collection
fusion_ui.ui_elements = {}

-- Initialize Fusion UI context
-- @param fusion Fusion object from Resolve
-- @return true if successful, false otherwise
function fusion_ui.init(fusion)
    if not fusion then
        logging.error("Cannot initialize Fusion UI: No Fusion object provided")
        return false
    end
    
    logging.info("Initializing Fusion UI framework")
    
    -- Store reference to Fusion object
    fusion_ui.fusion = fusion
    
    -- Try to create UI Manager
    local ui_manager = nil
    local success, result = pcall(function()
        return fusion.UIManager
    end)
    
    if success and result then
        fusion_ui.ui_manager = result
        logging.info("Successfully initialized Fusion UI Manager")
        return true
    else
        logging.error("Failed to get UI Manager from Fusion")
        return false
    end
end

-- Check if Fusion UI is available
-- @return Boolean indicating if Fusion UI is available
function fusion_ui.is_available()
    return fusion_ui.fusion ~= nil and fusion_ui.ui_manager ~= nil
end

-- Create a dialog using Fusion UI
-- @param title Dialog title
-- @param width Width of the dialog in pixels
-- @param height Height of the dialog in pixels
-- @return Dialog object if successful, nil otherwise
function fusion_ui.create_dialog(title, width, height)
    if not fusion_ui.is_available() then
        logging.error("Cannot create dialog: Fusion UI not available")
        return nil
    end
    
    width = width or 400
    height = height or 300
    
    local dialog = nil
    local success, result = pcall(function()
        local ui = fusion_ui.ui_manager
        return ui:AddDialog({
            WindowTitle = title,
            Geometry = { Width = width, Height = height },
            WindowFlags = { Window = true, WindowStaysOnTopHint = true }
        })
    end)
    
    if success and result then
        dialog = result
        -- Store reference to prevent garbage collection
        table.insert(fusion_ui.ui_elements, dialog)
        return dialog
    else
        logging.error("Failed to create dialog: " .. tostring(result))
        return nil
    end
end

-- Create a button using Fusion UI
-- @param parent Parent UI element
-- @param text Button text
-- @param callback Function to call when button is clicked
-- @param x X position
-- @param y Y position
-- @param width Width of the button in pixels
-- @param height Height of the button in pixels
-- @return Button object if successful, nil otherwise
function fusion_ui.create_button(parent, text, callback, x, y, width, height)
    if not fusion_ui.is_available() or not parent then
        logging.error("Cannot create button: Fusion UI not available or no parent provided")
        return nil
    end
    
    x = x or 0
    y = y or 0
    width = width or 100
    height = height or 30
    
    local button = nil
    local success, result = pcall(function()
        local ui = fusion_ui.ui_manager
        return ui:AddButton(parent, {
            Text = text,
            Geometry = { X = x, Y = y, Width = width, Height = height }
        })
    end)
    
    if success and result then
        button = result
        
        -- Connect the clicked signal to the callback if provided
        if callback and type(callback) == "function" then
            button.Clicked = callback
        end
        
        -- Store reference to prevent garbage collection
        table.insert(fusion_ui.ui_elements, button)
        return button
    else
        logging.error("Failed to create button: " .. tostring(result))
        return nil
    end
end

-- Create a label using Fusion UI
-- @param parent Parent UI element
-- @param text Label text
-- @param x X position
-- @param y Y position
-- @param width Width of the label in pixels
-- @param height Height of the label in pixels
-- @return Label object if successful, nil otherwise
function fusion_ui.create_label(parent, text, x, y, width, height)
    if not fusion_ui.is_available() or not parent then
        logging.error("Cannot create label: Fusion UI not available or no parent provided")
        return nil
    end
    
    x = x or 0
    y = y or 0
    width = width or 200
    height = height or 20
    
    local label = nil
    local success, result = pcall(function()
        local ui = fusion_ui.ui_manager
        return ui:AddLabel(parent, {
            Text = text,
            Geometry = { X = x, Y = y, Width = width, Height = height }
        })
    end)
    
    if success and result then
        label = result
        -- Store reference to prevent garbage collection
        table.insert(fusion_ui.ui_elements, label)
        return label
    else
        logging.error("Failed to create label: " .. tostring(result))
        return nil
    end
end

-- Create a text edit field using Fusion UI
-- @param parent Parent UI element
-- @param text Initial text
-- @param x X position
-- @param y Y position
-- @param width Width of the field in pixels
-- @param height Height of the field in pixels
-- @return Text edit object if successful, nil otherwise
function fusion_ui.create_text_edit(parent, text, x, y, width, height)
    if not fusion_ui.is_available() or not parent then
        logging.error("Cannot create text edit: Fusion UI not available or no parent provided")
        return nil
    end
    
    x = x or 0
    y = y or 0
    width = width or 200
    height = height or 30
    text = text or ""
    
    local text_edit = nil
    local success, result = pcall(function()
        local ui = fusion_ui.ui_manager
        return ui:AddTextEdit(parent, {
            Text = text,
            Geometry = { X = x, Y = y, Width = width, Height = height }
        })
    end)
    
    if success and result then
        text_edit = result
        -- Store reference to prevent garbage collection
        table.insert(fusion_ui.ui_elements, text_edit)
        return text_edit
    else
        logging.error("Failed to create text edit: " .. tostring(result))
        return nil
    end
end

-- Create a combo box (dropdown) using Fusion UI
-- @param parent Parent UI element
-- @param items Table of items to add to the combo box
-- @param x X position
-- @param y Y position
-- @param width Width of the combo box in pixels
-- @param height Height of the combo box in pixels
-- @return Combo box object if successful, nil otherwise
function fusion_ui.create_combo_box(parent, items, x, y, width, height)
    if not fusion_ui.is_available() or not parent then
        logging.error("Cannot create combo box: Fusion UI not available or no parent provided")
        return nil
    end
    
    x = x or 0
    y = y or 0
    width = width or 200
    height = height or 30
    items = items or {}
    
    local combo_box = nil
    local success, result = pcall(function()
        local ui = fusion_ui.ui_manager
        return ui:AddComboBox(parent, {
            Geometry = { X = x, Y = y, Width = width, Height = height }
        })
    end)
    
    if success and result then
        combo_box = result
        
        -- Add items to the combo box
        for _, item in ipairs(items) do
            combo_box:AddItem(item)
        end
        
        -- Store reference to prevent garbage collection
        table.insert(fusion_ui.ui_elements, combo_box)
        return combo_box
    else
        logging.error("Failed to create combo box: " .. tostring(result))
        return nil
    end
end

-- Create a slider using Fusion UI
-- @param parent Parent UI element
-- @param min Minimum value
-- @param max Maximum value
-- @param value Initial value
-- @param x X position
-- @param y Y position
-- @param width Width of the slider in pixels
-- @param height Height of the slider in pixels
-- @return Slider object if successful, nil otherwise
function fusion_ui.create_slider(parent, min, max, value, x, y, width, height)
    if not fusion_ui.is_available() or not parent then
        logging.error("Cannot create slider: Fusion UI not available or no parent provided")
        return nil
    end
    
    x = x or 0
    y = y or 0
    width = width or 200
    height = height or 30
    min = min or 0
    max = max or 100
    value = value or 50
    
    local slider = nil
    local success, result = pcall(function()
        local ui = fusion_ui.ui_manager
        return ui:AddSlider(parent, {
            Minimum = min,
            Maximum = max,
            Value = value,
            Geometry = { X = x, Y = y, Width = width, Height = height }
        })
    end)
    
    if success and result then
        slider = result
        -- Store reference to prevent garbage collection
        table.insert(fusion_ui.ui_elements, slider)
        return slider
    else
        logging.error("Failed to create slider: " .. tostring(result))
        return nil
    end
end

-- Show a file open dialog using Fusion UI
-- @param title Dialog title
-- @param directory Initial directory
-- @param filter File filter (e.g., "Video Files (*.mp4 *.mov)")
-- @param multi_select Allow multiple file selection
-- @return Selected file path(s) or nil if canceled
function fusion_ui.show_file_dialog(title, directory, filter, multi_select)
    if not fusion_ui.is_available() then
        logging.error("Cannot show file dialog: Fusion UI not available")
        return nil
    end
    
    local dialog_result = nil
    local success, result = pcall(function()
        local ui = fusion_ui.ui_manager
        
        if multi_select then
            return ui:OpenFileDialog({
                Title = title,
                StartDirectory = directory,
                Filter = filter,
                MultiSelect = true
            })
        else
            return ui:OpenFileDialog({
                Title = title,
                StartDirectory = directory,
                Filter = filter,
                MultiSelect = false
            })
        end
    end)
    
    if success and result then
        return result
    else
        logging.error("Failed to show file dialog: " .. tostring(result))
        return nil
    end
end

-- Show a file save dialog using Fusion UI
-- @param title Dialog title
-- @param directory Initial directory
-- @param filter File filter (e.g., "Drone Project (*.droneproj)")
-- @param default_name Default filename
-- @return Selected file path or nil if canceled
function fusion_ui.show_save_dialog(title, directory, filter, default_name)
    if not fusion_ui.is_available() then
        logging.error("Cannot show save dialog: Fusion UI not available")
        return nil
    end
    
    local dialog_result = nil
    local success, result = pcall(function()
        local ui = fusion_ui.ui_manager
        
        return ui:SaveFileDialog({
            Title = title,
            StartDirectory = directory,
            Filter = filter,
            DefaultName = default_name or ""
        })
    end)
    
    if success and result then
        return result
    else
        logging.error("Failed to show save dialog: " .. tostring(result))
        return nil
    end
end

-- Show a progress dialog using Fusion UI
-- @param title Dialog title
-- @param message Progress message
-- @param callback Function to execute with progress reporting
-- @return true if successful, false otherwise
function fusion_ui.show_progress(title, message, callback)
    if not fusion_ui.is_available() then
        logging.error("Cannot show progress dialog: Fusion UI not available")
        return false
    end
    
    -- Create dialog
    local dialog = fusion_ui.create_dialog(title, 400, 100)
    if not dialog then
        return false
    end
    
    -- Add message label
    local label = fusion_ui.create_label(dialog, message, 10, 10, 380, 30)
    
    -- Add progress bar
    local progress_bar = nil
    local success, result = pcall(function()
        local ui = fusion_ui.ui_manager
        return ui:AddProgressBar(dialog, {
            Minimum = 0,
            Maximum = 100,
            Value = 0,
            Geometry = { X = 10, Y = 50, Width = 380, Height = 30 }
        })
    end)
    
    if success and result then
        progress_bar = result
        table.insert(fusion_ui.ui_elements, progress_bar)
    else
        logging.error("Failed to create progress bar: " .. tostring(result))
        dialog:Hide()
        return false
    end
    
    -- Show dialog
    dialog:Show()
    
    -- Execute callback with progress reporting
    local timer = nil
    local success, result = pcall(function()
        local ui = fusion_ui.ui_manager
        return ui:AddTimer(dialog, 100)  -- 100ms interval
    end)
    
    if success and result then
        timer = result
        table.insert(fusion_ui.ui_elements, timer)
        
        -- Set up progress reporting
        local progress_state = { value = 0, done = false }
        
        -- Start the operation in a separate thread
        local thread = coroutine.create(function()
            local success = callback(function(percent)
                progress_state.value = percent
                if percent >= 100 then
                    progress_state.done = true
                end
            end)
            
            progress_state.done = true
            return success
        end)
        
        -- Resume the thread
        coroutine.resume(thread)
        
        -- Set timer callback to update progress bar
        timer.Timeout = function()
            progress_bar.Value = progress_state.value
            
            if progress_state.done then
                timer:Stop()
                dialog:Hide()
                
                -- Clean up
                local index = nil
                for i, elem in ipairs(fusion_ui.ui_elements) do
                    if elem == timer then
                        index = i
                        break
                    end
                end
                
                if index then
                    table.remove(fusion_ui.ui_elements, index)
                end
            end
        end
        
        timer:Start()
        return true
    else
        logging.error("Failed to create timer: " .. tostring(result))
        dialog:Hide()
        return false
    end
end

-- Show alert dialog with message
-- @param title Title of the dialog
-- @param message Message to display
-- @param icon Icon to show (optional: "info", "warning", "error")
-- @return true if user clicked OK, false otherwise
function fusion_ui.show_alert(title, message, icon)
    if not fusion_ui.is_available() then
        logging.error("Cannot show alert: Fusion UI not available")
        return false
    end
    
    local icon_type = "Information"
    if icon == "warning" then
        icon_type = "Warning"
    elseif icon == "error" then
        icon_type = "Critical"
    end
    
    local dialog_result = nil
    local success, result = pcall(function()
        local ui = fusion_ui.ui_manager
        return ui:ShowMessageDialog({
            Title = title,
            Text = message,
            Icon = icon_type,
            Buttons = { "OK" }
        })
    end)
    
    if success then
        return true  -- User clicked OK
    else
        logging.error("Failed to show alert: " .. tostring(result))
        return false
    end
end

-- Show confirmation dialog
-- @param title Title of the dialog
-- @param message Message to display
-- @return true if user confirmed, false otherwise
function fusion_ui.show_confirm(title, message)
    if not fusion_ui.is_available() then
        logging.error("Cannot show confirmation: Fusion UI not available")
        return false
    end
    
    local dialog_result = nil
    local success, result = pcall(function()
        local ui = fusion_ui.ui_manager
        return ui:ShowMessageDialog({
            Title = title,
            Text = message,
            Icon = "Question",
            Buttons = { "Yes", "No" },
            DefaultButton = "No"
        })
    end)
    
    if success and result == "Yes" then
        return true  -- User confirmed
    else
        return false  -- User denied or error occurred
    end
end

-- Create a vertical layout using Fusion UI
-- @param parent Parent UI element
-- @param x X position
-- @param y Y position
-- @param width Width of the layout in pixels
-- @param height Height of the layout in pixels
-- @return Layout object if successful, nil otherwise
function fusion_ui.create_vbox_layout(parent, x, y, width, height)
    if not fusion_ui.is_available() or not parent then
        logging.error("Cannot create vertical layout: Fusion UI not available or no parent provided")
        return nil
    end
    
    x = x or 0
    y = y or 0
    width = width or 200
    height = height or 200
    
    local layout = nil
    local success, result = pcall(function()
        local ui = fusion_ui.ui_manager
        return ui:AddLayout(parent, {
            Type = "VBox",
            Geometry = { X = x, Y = y, Width = width, Height = height }
        })
    end)
    
    if success and result then
        layout = result
        -- Store reference to prevent garbage collection
        table.insert(fusion_ui.ui_elements, layout)
        return layout
    else
        logging.error("Failed to create vertical layout: " .. tostring(result))
        return nil
    end
end

-- Create a horizontal layout using Fusion UI
-- @param parent Parent UI element
-- @param x X position
-- @param y Y position
-- @param width Width of the layout in pixels
-- @param height Height of the layout in pixels
-- @return Layout object if successful, nil otherwise
function fusion_ui.create_hbox_layout(parent, x, y, width, height)
    if not fusion_ui.is_available() or not parent then
        logging.error("Cannot create horizontal layout: Fusion UI not available or no parent provided")
        return nil
    end
    
    x = x or 0
    y = y or 0
    width = width or 200
    height = height or 200
    
    local layout = nil
    local success, result = pcall(function()
        local ui = fusion_ui.ui_manager
        return ui:AddLayout(parent, {
            Type = "HBox",
            Geometry = { X = x, Y = y, Width = width, Height = height }
        })
    end)
    
    if success and result then
        layout = result
        -- Store reference to prevent garbage collection
        table.insert(fusion_ui.ui_elements, layout)
        return layout
    else
        logging.error("Failed to create horizontal layout: " .. tostring(result))
        return nil
    end
end

-- Function to create and show color panel dialog
function fusion_ui.show_color_panel(resolve, project_obj)
    local dialog = fusion_ui.create_dialog("Color Grading", 400, 300)
    if not dialog then
        return false
    end
    
    -- Create title label
    fusion_ui.create_label(dialog, "Select LUT or Color Preset:", 10, 10, 380, 30)
    
    -- Create LUT combo box
    local lut_combo = fusion_ui.create_combo_box(dialog, 
        {"Default", "Cinematic", "Vintage", "Drone Aerial"}, 
        10, 50, 380, 30)
    
    -- Create intensity slider
    fusion_ui.create_label(dialog, "Intensity:", 10, 90, 380, 30)
    local intensity_slider = fusion_ui.create_slider(dialog, 0, 100, 50, 10, 120, 380, 30)
    local intensity_label = fusion_ui.create_label(dialog, "Intensity: 50%", 10, 160, 380, 30)
    
    -- Update intensity label when slider changes
    if intensity_slider then
        intensity_slider.ValueChanged = function(value)
            if intensity_label then
                intensity_label.Text = string.format("Intensity: %d%%", value)
            end
        end
    end
    
    -- Add buttons
    fusion_ui.create_button(dialog, "Apply LUT", function()
        local color_module = require("lib.color")
        local lut_name = lut_combo:GetCurrentText()
        local lut_path = color_module.get_lut_path(lut_name)
        
        if lut_path then
            if color_module.apply_lut(project_obj, lut_path) then
                fusion_ui.show_alert("Success", string.format("Applied %s LUT", lut_name), "info")
            else
                fusion_ui.show_alert("Error", "Failed to apply LUT", "error")
            end
        else
            fusion_ui.show_alert("Error", string.format("LUT %s not found", lut_name), "error")
        end
    }, 10, 200, 180, 30)
    
    fusion_ui.create_button(dialog, "Auto Color", function()
        local ai_simulation = require("ai_simulation")
        
        fusion_ui.show_progress("Auto Color", "Applying auto color grading...", function(progress_callback)
            local intensity = intensity_slider.Value / 100
            local success = ai_simulation.auto_color_grade(project_obj:GetCurrentTimeline(), intensity, progress_callback)
            
            if success then
                fusion_ui.show_alert("Success", "Applied auto color grading", "info")
            else
                fusion_ui.show_alert("Error", "Failed to apply auto color grading", "error")
            end
            
            return success
        end)
    }, 200, 200, 180, 30)
    
    fusion_ui.create_button(dialog, "Close", function()
        dialog:Hide()
    }, 10, 240, 380, 30)
    
    -- Show dialog
    dialog:Show()
    return true
end

-- Function to handle importing media
function fusion_ui.handle_import(resolve, project_obj, media_pool)
    local files = fusion_ui.show_file_dialog(
        "Import Media Files",
        os.getenv("HOME") or os.getenv("USERPROFILE"),
        "Video Files (*.mp4 *.mov *.avi)",
        true
    )
    
    if not files or #files == 0 then
        return
    end
    
    fusion_ui.show_progress("Importing Media", "Importing media files...", function(progress_callback)
        local mediapool = require("lib.mediapool")
        
        -- Show some progress updates
        for i = 1, 10 do
            progress_callback(i * 10)
            -- Small delay to simulate work
            pcall(function() os.execute("sleep 0.1") end)
        end
        
        local items = mediapool.import_media(media_pool, files)
        
        if items and #items > 0 then
            fusion_ui.show_alert("Import Complete", string.format("Successfully imported %d files", #items), "info")
            return true
        else
            fusion_ui.show_alert("Import Failed", "Failed to import media files", "error")
            return false
        end
    end)
    
    return true
end

-- Function to handle scene detection
function fusion_ui.handle_scene_detection(resolve, project_obj, media_pool)
    if not media_pool then
        fusion_ui.show_alert("Error", "Media pool not available", "error")
        return false
    end
    
    local root_folder = media_pool:GetRootFolder()
    if not root_folder then
        fusion_ui.show_alert("Error", "Cannot access media pool root folder", "error")
        return false
    end
    
    local clips = root_folder:GetClipList()
    if not clips or #clips == 0 then
        fusion_ui.show_alert("No Clips", "No clips found in media pool", "warning")
        return false
    end
    
    if not fusion_ui.show_confirm("Scene Detection", "Analyze " .. #clips .. " clips for scene changes?") then
        return false
    end
    
    fusion_ui.show_progress("Scene Detection", "Analyzing clips...", function(progress_callback)
        -- Run scene detection
        local ai_simulation = require("ai_simulation")
        local new_clips = ai_simulation.detect_scenes(clips, progress_callback)
        
        if new_clips and #new_clips > 0 then
            -- Create a new timeline with detected scenes
            local timeline_module = require("lib.timeline")
            local current_timeline = project_obj:GetCurrentTimeline()
            
            if current_timeline then
                -- Update existing timeline
                if fusion_ui.show_confirm("Update Timeline", "Update current timeline with detected scenes?") then
                    timeline_module.update_with_trimmed_clips(project_obj, media_pool, current_timeline, new_clips)
                    fusion_ui.show_alert("Scene Detection Complete", string.format("Updated timeline with %d scenes", #new_clips), "info")
                end
            else
                -- Create new timeline
                local new_timeline = timeline_module.create_from_clips(project_obj, media_pool, clips, "Drone Scenes")
                if new_timeline then
                    fusion_ui.show_alert("Scene Detection Complete", string.format("Created new timeline with %d scenes", #new_clips), "info")
                else
                    fusion_ui.show_alert("Timeline Creation Failed", "Failed to create new timeline", "error")
                end
            end
            
            return true
        else
            fusion_ui.show_alert("Scene Detection Failed", "No scenes detected", "warning")
            return false
        end
    end)
    
    return true
end

-- Function to handle auto edit
function fusion_ui.handle_auto_edit(resolve, project_obj, media_pool)
    if not media_pool then
        fusion_ui.show_alert("Error", "Media pool not available", "error")
        return false
    end
    
    local root_folder = media_pool:GetRootFolder()
    if not root_folder then
        fusion_ui.show_alert("Error", "Cannot access media pool root folder", "error")
        return false
    end
    
    local clips = root_folder:GetClipList()
    if not clips or #clips == 0 then
        fusion_ui.show_alert("No Clips", "No clips found in media pool", "warning")
        return false
    end
    
    if not fusion_ui.show_confirm("Auto Edit", "Create an automatic edit with all clips?") then
        return false
    end
    
    fusion_ui.show_progress("Auto Edit", "Creating automatic edit...", function(progress_callback)
        -- Auto edit workflow
        local timeline_module = require("lib.timeline")
        local color_module = require("lib.color")
        local ai_simulation = require("ai_simulation")
        
        -- Step 1: Create timeline
        progress_callback(10)
        local new_timeline = timeline_module.create_from_clips(project_obj, media_pool, clips, "Auto Drone Edit")
        if not new_timeline then
            fusion_ui.show_alert("Error", "Failed to create timeline", "error")
            return false
        end
        
        -- Step 2: Apply transitions
        progress_callback(30)
        timeline_module.apply_transitions(new_timeline)
        
        -- Step 3: Color grading
        progress_callback(50)
        local lut_path = color_module.get_lut_path("Drone Aerial")
        if lut_path then
            color_module.apply_lut(project_obj, lut_path)
        end
        
        -- Step 4: Audio enhancements
        progress_callback(70)
        ai_simulation.enhance_audio(new_timeline, {
            normalize = true,
            noise_reduction = 0.7,
            eq = true,
            compression = 0.5
        }, function(p)
            progress_callback(70 + p * 0.3)
        end)
        
        progress_callback(100)
        fusion_ui.show_alert("Auto Edit Complete", "Successfully created automatic edit", "info")
        return true
    end)
    
    return true
end

-- Function to show project management panel
function fusion_ui.show_project_panel(resolve, project_obj, media_pool)
    local dialog = fusion_ui.create_dialog("Project Management", 500, 400)
    if not dialog then
        return false
    end
    
    local project_module = require("lib.project")
    local summary = project_module.get_summary()
    
    -- Create title label
    fusion_ui.create_label(dialog, "Project Information", 10, 10, 480, 30)
    
    -- Create form fields
    fusion_ui.create_label(dialog, "Project Name:", 10, 50, 150, 30)
    local name_input = fusion_ui.create_text_edit(dialog, project_module.current.name, 170, 50, 320, 30)
    
    fusion_ui.create_label(dialog, "Description:", 10, 90, 150, 30)
    local desc_input = fusion_ui.create_text_edit(dialog, project_module.current.description, 170, 90, 320, 30)
    
    fusion_ui.create_label(dialog, "Created:", 10, 130, 150, 30)
    fusion_ui.create_label(dialog, summary.created, 170, 130, 320, 30)
    
    fusion_ui.create_label(dialog, "Modified:", 10, 170, 150, 30)
    fusion_ui.create_label(dialog, summary.modified, 170, 170, 320, 30)
    
    fusion_ui.create_label(dialog, "Timeline:", 10, 210, 150, 30)
    fusion_ui.create_label(dialog, summary.timeline_name, 170, 210, 320, 30)
    
    fusion_ui.create_label(dialog, "Clips:", 10, 250, 150, 30)
    fusion_ui.create_label(dialog, tostring(summary.clip_count), 170, 250, 320, 30)
    
    -- Add buttons
    fusion_ui.create_button(dialog, "New Project", function()
        if fusion_ui.show_confirm("New Project", "Create a new project? Any unsaved changes will be lost.") then
            project_module.new(name_input:GetText(), desc_input:GetText())
            fusion_ui.show_alert("Project Created", "New project created successfully", "info")
            dialog:Hide()
        end
    }, 10, 290, 150, 30)
    
    fusion_ui.create_button(dialog, "Save Project", function()
        local filepath = fusion_ui.show_save_dialog(
            "Save Project",
            os.getenv("HOME") or os.getenv("USERPROFILE"),
            "Drone Project (*.droneproj)",
            project_module.current.name:gsub("[^%w%s]", ""):gsub("%s+", "_") .. ".droneproj"
        )
        
        if filepath then
            -- Update project name and description from form
            project_module.current.name = name_input:GetText()
            project_module.current.description = desc_input:GetText()
            
            -- Save the project
            local success, err = project_module.save(filepath, project_obj, media_pool)
            
            if success then
                fusion_ui.show_alert("Project Saved", "Project saved successfully", "info")
                dialog:Hide()
            else
                fusion_ui.show_alert("Save Error", "Failed to save project: " .. (err or "Unknown error"), "error")
            end
        end
    }, 170, 290, 150, 30)
    
    fusion_ui.create_button(dialog, "Load Project", function()
        local filepath = fusion_ui.show_file_dialog(
            "Load Project",
            os.getenv("HOME") or os.getenv("USERPROFILE"),
            "Drone Project (*.droneproj)",
            false
        )
        
        if filepath then
            local success, err = project_module.load(filepath, project_obj, media_pool)
            
            if success then
                fusion_ui.show_alert("Project Loaded", "Project loaded successfully", "info")
                dialog:Hide()
            else
                fusion_ui.show_alert("Load Error", "Failed to load project: " .. (err or "Unknown error"), "error")
            end
        end
    }, 330, 290, 150, 30)
    
    fusion_ui.create_button(dialog, "Close", function()
        dialog:Hide()
    }, 10, 330, 480, 30)
    
    -- Show dialog
    dialog:Show()
    return true
end

-- Show the main application window
-- @param resolve Resolve object
-- @param project_obj Project object
-- @param media_pool MediaPool object
-- @return true if successful, false otherwise
function fusion_ui.show_main_window(resolve, project_obj, media_pool)
    if not fusion_ui.is_available() then
        logging.error("Cannot show main window: Fusion UI not available")
        return false
    end
    
    -- Get Fusion from Resolve if not provided
    if not fusion_ui.fusion and resolve then
        local success, fusion = pcall(function()
            return resolve:GetFusion()
        end)
        
        if success and fusion then
            fusion_ui.init(fusion)
        else
            logging.error("Failed to get Fusion from Resolve")
            return false
        end
    end
    
    -- Create main window
    local window = fusion_ui.create_dialog("Drone Editor", 800, 600)
    if not window then
        return false
    end
    
    -- Add toolbar (horizontal layout at the top)
    local toolbar = fusion_ui.create_hbox_layout(window, 10, 10, 780, 40)
    if toolbar then
        -- Add buttons to toolbar
        fusion_ui.create_button(toolbar, "Import Media", function()
            fusion_ui.handle_import(resolve, project_obj, media_pool)
        }, 0, 0, 120, 30)
        
        fusion_ui.create_button(toolbar, "Detect Scenes", function()
            fusion_ui.handle_scene_detection(resolve, project_obj, media_pool)
        }, 130, 0, 120, 30)
        
        fusion_ui.create_button(toolbar, "Color Grading", function()
            fusion_ui.show_color_panel(resolve, project_obj)
        }, 260, 0, 120, 30)
        
        fusion_ui.create_button(toolbar, "Auto Edit", function()
            fusion_ui.handle_auto_edit(resolve, project_obj, media_pool)
        }, 390, 0, 120, 30)
        
        fusion_ui.create_button(toolbar, "Project Settings", function()
            fusion_ui.show_project_panel(resolve, project_obj, media_pool)
        }, 520, 0, 120, 30)
        
        fusion_ui.create_button(toolbar, "Exit", function()
            window:Hide()
        }, 650, 0, 120, 30)
    end
    
    -- Add status label
    local status_label = fusion_ui.create_label(window, "Ready", 10, 560, 780, 30)
    
    -- Show the window
    window:Show()
    
    -- Setup auto-update timer
    local timer = nil
    local success, result = pcall(function()
        local ui = fusion_ui.ui_manager
        return ui:AddTimer(window, 1000)  -- 1 second interval
    end)
    
    if success and result then
        timer = result
        table.insert(fusion_ui.ui_elements, timer)
        
        -- Handle UI events and updates
        timer.Timeout = function()
            -- Update status label with current project info
            if project_obj then
                local project_name = "No project"
                
                pcall(function()
                    project_name = project_obj:GetName()
                end)
                
                if status_label then
                    status_label.Text = "Current project: " .. project_name
                end
            end
        end
        
        timer:Start()
    end
    
    return true
end

-- Function to detect the environment
-- @return "fusion", "resolve", "standalone", or "unknown"
function fusion_ui.detect_environment()
    -- Check if we're in Fusion standalone
    if fusion then
        return "fusion"
    end
    
    -- Check if bmd global is available (Resolve)
    if bmd then
        local success, fusion_app = pcall(function() return bmd.scriptapp("Fusion") end)
        if success and fusion_app then
            return "resolve"
        end
    end
    
    -- Check if we have a UI module
    local success, ui_module = pcall(require, "ui")
    if success and ui_module then
        return "standalone"
    end
    
    return "unknown"
end

-- Initialize the appropriate UI based on environment
function fusion_ui.initialize_ui()
    local env = fusion_ui.detect_environment()
    
    if env == "resolve" then
        -- We're in DaVinci Resolve, try to get Fusion
        local success, fusion_app = pcall(function() return bmd.scriptapp("Fusion") end)
        if success and fusion_app then
            return fusion_ui.init(fusion_app)
        end
    elseif env == "fusion" then
        -- We're in Fusion standalone
        return fusion_ui.init(fusion)
    elseif env == "standalone" then
        -- We're in standalone mode, can't use Fusion UI
        logging.info("Running in standalone mode, Fusion UI not available")
        return false
    end
    
    logging.warning("Unknown environment, cannot initialize Fusion UI")
    return false
end

return fusion_ui