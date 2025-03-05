-- UI Module for Drone Editor
-- Handles user interface components and interactions

local logging = require("logging")
local settings = require("settings")
local ai_simulation = require("ai_simulation")
local timeline = require("lib.timeline")
local color = require("lib.color")
local project = require("lib.project")  -- Add project module

local ui = {}

-- Check if UI should be shown or console mode used
-- @return Boolean indicating if UI should be shown
function ui.should_show_ui()
    return not (arg and arg[1] == "--console")
end

-- Create a button with standard properties
-- @param parent Parent UI component
-- @param text Button text
-- @param callback Function to call when button is clicked
-- @return Button UI component
local function create_button(parent, text, callback)
    local button = ui.Button{
        Text = text,
        Parent = parent
    }
    
    button.Clicked = callback
    return button
end

-- Create a labeled input field with standard properties
-- @param parent Parent UI component
-- @param label Label text
-- @param default_value Default value for the input
-- @return Input UI component
local function create_input(parent, label, default_value)
    local label_ui = ui.Label{
        Text = label,
        Parent = parent
    }
    
    local input = ui.TextEdit{
        Text = default_value or "",
        Parent = parent
    }
    
    return input
end

-- Show a progress dialog for long-running operations
-- @param title Title of the dialog
-- @param message Message to show
-- @param callback Function to execute with progress reporting
function ui.show_progress(title, message, callback)
    local dialog = ui.Dialog{
        WindowTitle = title,
        Geometry = {Width = 400, Height = 100}
    }
    
    local layout = ui.VBoxLayout{Parent = dialog}
    
    ui.Label{
        Text = message,
        Parent = layout
    }
    
    local progress = ui.ProgressBar{
        Parent = layout,
        Minimum = 0,
        Maximum = 100,
        Value = 0
    }
    
    dialog:Show()
    
    -- Execute the callback with progress reporting
    ui.do_async(function()
        local success = callback(function(percent)
            progress.Value = percent
        end)
        
        dialog:Close()
        return success
    end)
end

-- Show alert dialog with message
-- @param title Title of the dialog
-- @param message Message to display
-- @param icon Icon to show (optional: "info", "warning", "error")
function ui.show_alert(title, message, icon)
    local dialog = ui.MessageBox{
        WindowTitle = title,
        Text = message
    }
    
    if icon == "warning" then
        dialog.Icon = ui.MessageBox.Warning
    elseif icon == "error" then
        dialog.Icon = ui.MessageBox.Critical
    else
        dialog.Icon = ui.MessageBox.Information
    end
    
    dialog:Show()
end

-- Show confirmation dialog
-- @param title Title of the dialog
-- @param message Message to display
-- @return Boolean indicating user confirmation
function ui.show_confirm(title, message)
    local dialog = ui.MessageBox{
        WindowTitle = title,
        Text = message,
        Icon = ui.MessageBox.Question,
        Buttons = {ui.MessageBox.Yes, ui.MessageBox.No},
        DefaultButton = ui.MessageBox.No
    }
    
    return dialog:Show() == ui.MessageBox.Yes
end

-- Show file selection dialog
-- @param title Title of the dialog
-- @param directory Starting directory
-- @param filter File filter (e.g., "Video Files (*.mp4 *.mov)")
-- @param multi_select Allow multiple file selection
-- @return Selected file path(s) or nil if canceled
function ui.show_file_dialog(title, directory, filter, multi_select)
    local dialog
    
    if multi_select then
        dialog = ui.FileDialog.getOpenFileNames{
            WindowTitle = title,
            Directory = directory,
            Filter = filter
        }
    else
        dialog = ui.FileDialog.getOpenFileName{
            WindowTitle = title,
            Directory = directory,
            Filter = filter
        }
    end
    
    return dialog
end

-- Show file save dialog
-- @param title Title of the dialog
-- @param directory Starting directory
-- @param filter File filter (e.g., "Drone Project (*.droneproj)")
-- @param default_name Default filename
-- @return Selected file path or nil if canceled
function ui.show_save_dialog(title, directory, filter, default_name)
    local dialog = ui.FileDialog.getSaveFileName{
        WindowTitle = title,
        Directory = directory and (directory .. "/" .. (default_name or "")) or (default_name or ""),
        Filter = filter
    }
    
    return dialog
end

-- Handle importing media files
-- @param resolve Resolve object
-- @param project_obj Project object
-- @param media_pool MediaPool object
function ui.handle_import(resolve, project_obj, media_pool)
    local files = ui.show_file_dialog(
        "Import Media Files",
        os.getenv("HOME") or os.getenv("USERPROFILE"),
        "Video Files (*.mp4 *.mov *.avi)",
        true
    )
    
    if not files or #files == 0 then
        return
    end
    
    ui.show_progress("Importing Media", "Importing media files...", function(progress_callback)
        local mediapool = require("lib.mediapool")
        local items = mediapool.import_media(media_pool, files)
        
        if items and #items > 0 then
            ui.show_alert("Import Complete", string.format("Successfully imported %d files", #items), "info")
            return true
        else
            ui.show_alert("Import Failed", "Failed to import media files", "error")
            return false
        end
    end)
end

-- Handle scene detection
-- @param resolve Resolve object
-- @param project_obj Project object
-- @param media_pool MediaPool object
function ui.handle_scene_detection(resolve, project_obj, media_pool)
    local root_folder = media_pool:GetRootFolder()
    if not root_folder then
        ui.show_alert("Error", "Cannot access media pool root folder", "error")
        return
    end
    
    local clips = root_folder:GetClipList()
    if not clips or #clips == 0 then
        ui.show_alert("No Clips", "No clips found in media pool", "warning")
        return
    end
    
    if not ui.show_confirm("Scene Detection", "Analyze " .. #clips .. " clips for scene changes?") then
        return
    end
    
    ui.show_progress("Scene Detection", "Analyzing clips...", function(progress_callback)
        -- Run scene detection
        local new_clips = ai_simulation.detect_scenes(clips, progress_callback)
        
        if new_clips and #new_clips > 0 then
            -- Create a new timeline with detected scenes
            local timeline_module = require("lib.timeline")
            local current_timeline = project_obj:GetCurrentTimeline()
            
            if current_timeline then
                -- Update existing timeline
                if ui.show_confirm("Update Timeline", "Update current timeline with detected scenes?") then
                    timeline_module.update_with_trimmed_clips(project_obj, media_pool, current_timeline, new_clips)
                    ui.show_alert("Scene Detection Complete", string.format("Updated timeline with %d scenes", #new_clips), "info")
                end
            else
                -- Create new timeline
                local new_timeline = timeline_module.create_from_clips(project_obj, media_pool, clips, "Drone Scenes")
                if new_timeline then
                    ui.show_alert("Scene Detection Complete", string.format("Created new timeline with %d scenes", #new_clips), "info")
                else
                    ui.show_alert("Timeline Creation Failed", "Failed to create new timeline", "error")
                end
            end
            
            return true
        else
            ui.show_alert("Scene Detection Failed", "No scenes detected", "warning")
            return false
        end
    end)
end

-- Show color grading panel
-- @param resolve Resolve object
-- @param project_obj Project object
function ui.show_color_panel(resolve, project_obj)
    local dialog = ui.Dialog{
        WindowTitle = "Color Grading",
        Geometry = {Width = 400, Height = 300}
    }
    
    local layout = ui.VBoxLayout{Parent = dialog}
    
    ui.Label{
        Text = "Select LUT or Color Preset:",
        Parent = layout
    }
    
    local lut_combo = ui.ComboBox{
        Parent = layout
    }
    
    -- Add LUT options
    lut_combo:AddItems({"Default", "Cinematic", "Vintage", "Drone Aerial"})
    
    -- Add preset options
    local intensity_slider = ui.Slider{
        Parent = layout,
        Minimum = 0,
        Maximum = 100,
        Value = 50,
        Orientation = ui.Horizontal
    }
    
    local intensity_label = ui.Label{
        Text = "Intensity: 50%",
        Parent = layout
    }
    
    intensity_slider.ValueChanged = function(value)
        intensity_label.Text = string.format("Intensity: %d%%", value)
    end
    
    -- Add buttons
    local button_layout = ui.HBoxLayout{Parent = layout}
    
    create_button(button_layout, "Apply LUT", function()
        local lut_name = lut_combo:CurrentText()
        local lut_path = color.get_lut_path(lut_name)
        
        if lut_path then
            if color.apply_lut(project_obj, lut_path) then
                ui.show_alert("Success", string.format("Applied %s LUT", lut_name), "info")
            else
                ui.show_alert("Error", "Failed to apply LUT", "error")
            end
        else
            ui.show_alert("Error", string.format("LUT %s not found", lut_name), "error")
        end
    end)
    
    create_button(button_layout, "Auto Color", function()
        ui.show_progress("Auto Color", "Applying auto color grading...", function(progress_callback)
            local intensity = intensity_slider.Value / 100
            local success = ai_simulation.auto_color_grade(project_obj:GetCurrentTimeline(), intensity, progress_callback)
            
            if success then
                ui.show_alert("Success", "Applied auto color grading", "info")
            else
                ui.show_alert("Error", "Failed to apply auto color grading", "error")
            end
            
            return success
        end)
    end)
    
    create_button(button_layout, "Close", function()
        dialog:Close()
    end)
    
    dialog:Show()
end

-- Show project management panel
-- @param resolve Resolve object
-- @param project_obj Project object
-- @param media_pool MediaPool object
function ui.show_project_panel(resolve, project_obj, media_pool)
    local dialog = ui.Dialog{
        WindowTitle = "Project Management",
        Geometry = {Width = 500, Height = 400}
    }
    
    local layout = ui.VBoxLayout{Parent = dialog}
    
    -- Project info section
    local info_group = ui.GroupBox{
        Title = "Project Information",
        Parent = layout
    }
    
    local info_layout = ui.FormLayout{Parent = info_group}
    
    local name_input = create_input(info_layout, "Project Name:", project.current.name)
    local desc_input = create_input(info_layout, "Description:", project.current.description)
    
    local summary = project.get_summary()
    
    ui.Label{
        Text = "Created: " .. summary.created,
        Parent = info_layout
    }
    
    ui.Label{
        Text = "Modified: " .. summary.modified,
        Parent = info_layout
    }
    
    ui.Label{
        Text = "Timeline: " .. summary.timeline_name,
        Parent = info_layout
    }
    
    ui.Label{
        Text = "Clips: " .. summary.clip_count,
        Parent = info_layout
    }
    
    -- Project actions
    local actions_layout = ui.HBoxLayout{Parent = layout}
    
    create_button(actions_layout, "New Project", function()
        if ui.show_confirm("New Project", "Create a new project? Any unsaved changes will be lost.") then
            project.new(name_input:GetText(), desc_input:GetText())
            ui.show_alert("Project Created", "New project created successfully", "info")
            dialog:Close()
        end
    end)
    
    create_button(actions_layout, "Save Project", function()
        local filepath = ui.show_save_dialog(
            "Save Project",
            os.getenv("HOME") or os.getenv("USERPROFILE"),
            "Drone Project (*.droneproj)",
            project.current.name:gsub("[^%w%s]", ""):gsub("%s+", "_") .. ".droneproj"
        )
        
        if filepath then
            -- Update project name and description from form
            project.current.name = name_input:GetText()
            project.current.description = desc_input:GetText()
            
            -- Save the project
            local success, err = project.save(filepath, project_obj, media_pool)
            
            if success then
                ui.show_alert("Project Saved", "Project saved successfully", "info")
                dialog:Close()
            else
                ui.show_alert("Save Error", "Failed to save project: " .. (err or "Unknown error"), "error")
            end
        end
    end)
    
    create_button(actions_layout, "Load Project", function()
        local filepath = ui.show_file_dialog(
            "Load Project",
            os.getenv("HOME") or os.getenv("USERPROFILE"),
            "Drone Project (*.droneproj)",
            false
        )
        
        if filepath then
            local success, err = project.load(filepath, project_obj, media_pool)
            
            if success then
                ui.show_alert("Project Loaded", "Project loaded successfully", "info")
                dialog:Close()
            else
                ui.show_alert("Load Error", "Failed to load project: " .. (err or "Unknown error"), "error")
            end
        end
    end)
    
    create_button(actions_layout, "Close", function()
        dialog:Close()
    end)
    
    dialog:Show()
end

-- Show the main application window
-- @param resolve Resolve object
-- @param project_obj Project object
-- @param media_pool MediaPool object
function ui.show_main_window(resolve, project_obj, media_pool)
    local window = ui.MainWindow{
        WindowTitle = "Drone Editor",
        Geometry = {Width = 800, Height = 600}
    }
    
    -- Create main layout
    local main_layout = ui.VBoxLayout{Parent = window}
    
    -- Create menu bar
    local menu_bar = ui.MenuBar{Parent = window}
    
    -- File menu
    local file_menu = menu_bar:AddMenu("File")
    file_menu:AddAction("New Project", function()
        if ui.show_confirm("New Project", "Create a new project? Any unsaved changes will be lost.") then
            project.new("Untitled Drone Project", "")
            ui.show_alert("Project Created", "New project created successfully", "info")
        end
    end)
    
    file_menu:AddAction("Open Project...", function()
        local filepath = ui.show_file_dialog(
            "Open Project",
            os.getenv("HOME") or os.getenv("USERPROFILE"),
            "Drone Project (*.droneproj)",
            false
        )
        
        if filepath then
            local success, err = project.load(filepath, project_obj, media_pool)
            
            if success then
                ui.show_alert("Project Loaded", "Project loaded successfully", "info")
            else
                ui.show_alert("Load Error", "Failed to load project: " .. (err or "Unknown error"), "error")
            end
        end
    end)
    
    file_menu:AddAction("Save Project", function()
        if project.current.last_save_path then
            local success, err = project.save(project.current.last_save_path, project_obj, media_pool)
            
            if success then
                ui.show_alert("Project Saved", "Project saved successfully", "info")
            else
                ui.show_alert("Save Error", "Failed to save project: " .. (err or "Unknown error"), "error")
            end
        else
            file_menu:ExecuteAction("Save Project As...")
        end
    end)
    
    file_menu:AddAction("Save Project As...", function()
        local filepath = ui.show_save_dialog(
            "Save Project As",
            os.getenv("HOME") or os.getenv("USERPROFILE"),
            "Drone Project (*.droneproj)",
            project.current.name:gsub("[^%w%s]", ""):gsub("%s+", "_") .. ".droneproj"
        )
        
        if filepath then
            local success, err = project.save(filepath, project_obj, media_pool)
            
            if success then
                project.current.last_save_path = filepath
                ui.show_alert("Project Saved", "Project saved successfully", "info")
            else
                ui.show_alert("Save Error", "Failed to save project: " .. (err or "Unknown error"), "error")
            end
        end
    end)
    
    file_menu:AddSeparator()
    
    file_menu:AddAction("Import Media...", function()
        ui.handle_import(resolve, project_obj, media_pool)
    end)
    
    file_menu:AddSeparator()
    
    file_menu:AddAction("Exit", function()
        if ui.show_confirm("Exit", "Exit Drone Editor? Any unsaved changes will be lost.") then
            window:Close()
        end
    end)
    
    -- Edit menu
    local edit_menu = menu_bar:AddMenu("Edit")
    edit_menu:AddAction("Project Settings...", function()
        ui.show_project_panel(resolve, project_obj, media_pool)
    end)
    
    edit_menu:AddSeparator()
    
    edit_menu:AddAction("Preferences...", function()
        -- Show preferences dialog (to be implemented)
    end)
    
    -- AI menu
    local ai_menu = menu_bar:AddMenu("AI Tools")
    ai_menu:AddAction("Detect Scenes", function()
        ui.handle_scene_detection(resolve, project_obj, media_pool)
    end)
    
    ai_menu:AddAction("Auto Color Grade", function()
        ui.show_color_panel(resolve, project_obj)
    end)
    
    ai_menu:AddAction("Enhance Audio", function()
        ui.show_progress("Audio Enhancement", "Enhancing audio...", function(progress_callback)
            local current_timeline = project_obj:GetCurrentTimeline()
            if not current_timeline then
                ui.show_alert("No Timeline", "No current timeline found", "warning")
                return false
            end
            
            local success = ai_simulation.enhance_audio(current_timeline, {
                normalize = true,
                noise_reduction = 0.7,
                eq = true,
                compression = 0.5
            }, progress_callback)
            
            if success then
                ui.show_alert("Success", "Enhanced audio successfully", "info")
            else
                ui.show_alert("Error", "Failed to enhance audio", "error")
            end
            
            return success
        end)
    end)
    
    ai_menu:AddAction("Smart Highlights", function()
        ui.show_progress("Smart Highlights", "Detecting highlights...", function(progress_callback)
            local root_folder = media_pool:GetRootFolder()
            if not root_folder then
                ui.show_alert("Error", "Cannot access media pool root folder", "error")
                return false
            end
            
            local clips = root_folder:GetClipList()
            if not clips or #clips == 0 then
                ui.show_alert("No Clips", "No clips found in media pool", "warning")
                return false
            end
            
            local highlights = ai_simulation.smart_highlight(clips, progress_callback)
            
            if highlights and #highlights > 0 then
                -- Create highlights timeline
                local timeline_name = "Drone Highlights"
                local highlights_clips = {}
                
                -- Extract only the top 5 highlights or fewer if less available
                local top_count = math.min(5, #highlights)
                for i = 1, top_count do
                    table.insert(highlights_clips, highlights[i])
                end
                
                local new_timeline = timeline.create_from_clips(project_obj, media_pool, highlights_clips, timeline_name)
                
                if new_timeline then
                    ui.show_alert("Highlights Created", string.format("Created highlights timeline with %d clips", top_count), "info")
                    return true
                else
                    ui.show_alert("Timeline Creation Failed", "Failed to create highlights timeline", "error")
                    return false
                end
            else
                ui.show_alert("No Highlights", "No highlights detected", "warning")
                return false
            end
        end)
    end)
    
    ai_menu:AddSeparator()
    
    ai_menu:AddAction("Auto Edit", function()
        -- Auto edit workflow
        ui.show_progress("Auto Edit", "Creating automatic edit...", function(progress_callback)
            -- Step 1: Get clips
            local root_folder = media_pool:GetRootFolder()
            local clips = root_folder:GetClipList()
            if not clips or #clips == 0 then
                ui.show_alert("No Clips", "No clips found in media pool", "warning")
                return false
            end
            
            -- Step 2: Detect scenes
            progress_callback(10)
            local scenes = ai_simulation.detect_scenes(clips, function(p)
                progress_callback(10 + p * 0.3)
            end)
            
            -- Step 3: Create timeline
            progress_callback(40)
            local new_timeline = timeline.create_from_clips(project_obj, media_pool, clips, "Auto Drone Edit")
            if not new_timeline then
                ui.show_alert("Error", "Failed to create timeline", "error")
                return false
            end
            
            -- Step 4: Apply transitions
            progress_callback(50)
            timeline.apply_transitions(new_timeline)
            
            -- Step 5: Color grading
            progress_callback(60)
            local lut_path = color.get_lut_path("Drone Aerial")
            if lut_path then
                color.apply_lut(project_obj, lut_path)
            end
            
            -- Step 6: Audio enhancements
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
            ui.show_alert("Auto Edit Complete", "Successfully created automatic edit", "info")
            return true
        end)
    end)
    
    -- Help menu
    local help_menu = menu_bar:AddMenu("Help")
    help_menu:AddAction("User Guide", function()
        -- Open user guide (to be implemented)
    end)
    
    help_menu:AddAction("About", function()
        ui.show_alert("About Drone Editor", "Drone Editor v1.0\n\nA specialized video editing automation tool for drone footage.", "info")
    end)
    
    -- Create toolbar
    local toolbar_layout = ui.HBoxLayout{Parent = main_layout}
    
    create_button(toolbar_layout, "Import Media", function()
        ui.handle_import(resolve, project_obj, media_pool)
    end)
    
    create_button(toolbar_layout, "Detect Scenes", function()
        ui.handle_scene_detection(resolve, project_obj, media_pool)
    end)
    
    create_button(toolbar_layout, "Color Grading", function()
        ui.show_color_panel(resolve, project_obj)
    end)
    
    create_button(toolbar_layout, "Auto Edit", function()
        ai_menu:ExecuteAction("Auto Edit")
    end)
    
    create_button(toolbar_layout, "Project Settings", function()
        ui.show_project_panel(resolve, project_obj, media_pool)
    end)
    
    -- Create main content area
    local content_layout = ui.HBoxLayout{Parent = main_layout}
    content_layout:SetStretch(1)
    
    -- Left panel for clips and media
    local left_panel = ui.GroupBox{
        Title = "Media",
        Parent = content_layout
    }
    
    -- Setup timer for autosave
    local autosave_timer = ui.Timer()
    autosave_timer.Interval = 5 * 60 * 1000 -- 5 minutes
    autosave_timer.Timeout = function()
        project.autosave(project_obj, media_pool)
    end
    autosave_timer:Start()
    
    -- Create status bar
    local status_bar = ui.StatusBar{Parent = window}
    status_bar:ShowMessage("Ready")
    
    -- Show the window
    window:Show()
    
    -- Start the UI event loop
    return ui.exec()
end

return ui