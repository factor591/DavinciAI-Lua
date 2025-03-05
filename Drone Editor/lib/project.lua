-- Project Management Module
-- Handles saving and loading of project files (.droneproj)

local logging = require("logging")
local settings = require("settings")
local mediapool = require("lib.mediapool")
local timeline = require("lib.timeline")

local project = {}

-- Project file format version
project.VERSION = "1.0"

-- Project data structure
-- @param name Project name
-- @param description Project description
-- @return New project data structure
function project.create_data(name, description)
    return {
        version = project.VERSION,
        name = name or "Untitled Drone Project",
        description = description or "",
        created = os.time(),
        modified = os.time(),
        settings = {},
        timeline_data = {},
        clip_data = {}
    }
end

-- Current project data
project.current = project.create_data()

-- Save project to file
-- @param filepath Path to save the project file
-- @param resolve_project DaVinci Resolve project object
-- @param media_pool MediaPool object
-- @return true if successful, false and error message otherwise
function project.save(filepath, resolve_project, media_pool)
    if not filepath or not resolve_project then
        return false, "Missing required parameters"
    end
    
    logging.info("Saving project to: " .. filepath)
    
    -- Update project data
    project.current.modified = os.time()
    project.current.resolve_project_name = resolve_project:GetName()
    
    -- Get current timeline
    local current_timeline = resolve_project:GetCurrentTimeline()
    if current_timeline then
        project.current.current_timeline_name = current_timeline:GetName()
        
        -- Save timeline data
        project.current.timeline_data = {
            name = current_timeline:GetName(),
            fps = current_timeline:GetSetting("timelineFrameRate") or 30,
            resolution = {
                width = current_timeline:GetSetting("timelineResolutionWidth") or 1920,
                height = current_timeline:GetSetting("timelineResolutionHeight") or 1080
            }
        }
        
        -- Save clip references
        local clips = {}
        local video_items = current_timeline:GetItemListInTrack("video", 1)
        if video_items and #video_items > 0 then
            for i, item in ipairs(video_items) do
                -- Try to get the media pool item
                local media_item = nil
                local success, result = pcall(function()
                    if item.GetMediaPoolItem and type(item.GetMediaPoolItem) == "function" then
                        return item:GetMediaPoolItem()
                    end
                    return nil
                end)
                
                if success and result then
                    media_item = result
                    
                    -- Get clip data
                    local clip_data = {
                        index = i,
                        name = timeline.get_clip_name(media_item),
                        start_frame = item:GetStart(),
                        end_frame = item:GetEnd(),
                        file_path = media_item:GetClipProperty("File Path")
                    }
                    
                    table.insert(clips, clip_data)
                end
            end
        end
        
        project.current.clip_data = clips
    end
    
    -- Save current settings
    for k, v in pairs(settings) do
        if type(v) ~= "function" then
            project.current.settings[k] = v
        end
    end
    
    -- Convert to JSON
    local json_str
    local success, result = pcall(function()
        return require("json").encode(project.current)
    end)
    
    if not success then
        logging.error("Error encoding project data: " .. tostring(result))
        return false, "Error encoding project data"
    end
    
    json_str = result
    
    -- Write to file
    local file, err = io.open(filepath, "w")
    if not file then
        logging.error("Error opening file for writing: " .. tostring(err))
        return false, "Could not open file: " .. tostring(err)
    end
    
    file:write(json_str)
    file:close()
    
    logging.info("Project saved successfully")
    return true
end

-- Load project from file
-- @param filepath Path to the project file
-- @param resolve_project DaVinci Resolve project object
-- @param media_pool MediaPool object
-- @return true if successful, false and error message otherwise
function project.load(filepath, resolve_project, media_pool)
    if not filepath or not resolve_project or not media_pool then
        return false, "Missing required parameters"
    end
    
    logging.info("Loading project from: " .. filepath)
    
    -- Check if file exists
    local file = io.open(filepath, "r")
    if not file then
        logging.error("Project file not found: " .. filepath)
        return false, "Project file not found"
    end
    
    -- Read the file
    local content = file:read("*all")
    file:close()
    
    if not content or content == "" then
        logging.error("Empty project file")
        return false, "Empty project file"
    end
    
    -- Parse JSON
    local project_data
    local success, result = pcall(function()
        return require("json").decode(content)
    end)
    
    if not success or not result then
        logging.error("Error decoding project data: " .. tostring(result))
        return false, "Invalid project file format"
    end
    
    project_data = result
    
    -- Check version
    if not project_data.version then
        logging.error("Project file has no version information")
        return false, "Invalid project file format"
    end
    
    -- Store the loaded project data
    project.current = project_data
    
    -- Apply settings
    if project_data.settings then
        for k, v in pairs(project_data.settings) do
            settings.set(k, v)
        end
    end
    
    -- Recreate timeline if needed
    if project_data.clip_data and #project_data.clip_data > 0 then
        local timeline_name = project_data.timeline_data and project_data.timeline_data.name or "Imported Timeline"
        
        -- Try to find existing timeline
        local existing_timeline = nil
        for i = 1, resolve_project:GetTimelineCount() do
            local timeline_obj = resolve_project:GetTimelineByIndex(i)
            if timeline_obj and timeline_obj:GetName() == timeline_name then
                existing_timeline = timeline_obj
                break
            end
        end
        
        if not existing_timeline then
            logging.info("Creating new timeline from project data: " .. timeline_name)
            
            -- Import clips
            local clips_to_import = {}
            for _, clip_data in ipairs(project_data.clip_data) do
                if clip_data.file_path then
                    -- Check if the clip already exists in the media pool
                    local existing_clip = mediapool.get_item_by_name(media_pool, clip_data.name)
                    
                    if not existing_clip then
                        -- Import the clip if it doesn't exist
                        local imported = mediapool.import_media(media_pool, {clip_data.file_path})
                        if imported and #imported > 0 then
                            table.insert(clips_to_import, imported[1])
                        end
                    else
                        table.insert(clips_to_import, existing_clip)
                    end
                end
            end
            
            -- Create timeline
            if #clips_to_import > 0 then
                local new_timeline = timeline.create_from_clips(resolve_project, media_pool, clips_to_import, timeline_name)
                
                -- Apply timeline settings if available
                if new_timeline and project_data.timeline_data then
                    if project_data.timeline_data.fps then
                        new_timeline:SetSetting("timelineFrameRate", project_data.timeline_data.fps)
                    end
                    
                    if project_data.timeline_data.resolution then
                        new_timeline:SetSetting("timelineResolutionWidth", project_data.timeline_data.resolution.width)
                        new_timeline:SetSetting("timelineResolutionHeight", project_data.timeline_data.resolution.height)
                    end
                end
            end
        else
            logging.info("Timeline already exists: " .. timeline_name)
            resolve_project:SetCurrentTimeline(existing_timeline)
        end
    end
    
    logging.info("Project loaded successfully")
    return true
end

-- Create a new project
-- @param name Project name
-- @param description Project description
-- @return true if successful, false otherwise
function project.new(name, description)
    project.current = project.create_data(name, description)
    return true
end

-- Get a summary of the current project
-- @return Table with project summary information
function project.get_summary()
    local summary = {
        name = project.current.name,
        description = project.current.description,
        created = os.date("%Y-%m-%d %H:%M:%S", project.current.created),
        modified = os.date("%Y-%m-%d %H:%M:%S", project.current.modified),
        timeline_name = project.current.timeline_data and project.current.timeline_data.name or "None",
        clip_count = project.current.clip_data and #project.current.clip_data or 0
    }
    
    return summary
end

-- Create an autosave filename
-- @param base_path Base directory path
-- @return Autosave filename
function project.create_autosave_filename(base_path)
    base_path = base_path or os.getenv("TEMP") or os.getenv("TMP") or "."
    local date_str = os.date("%Y%m%d_%H%M%S")
    local name = project.current.name:gsub("[^%w%s]", ""):gsub("%s+", "_")
    
    return base_path .. "/" .. name .. "_" .. date_str .. "_autosave.droneproj"
end

-- Autosave the current project
-- @param resolve_project DaVinci Resolve project object
-- @param media_pool MediaPool object
-- @return true if successful, false otherwise
function project.autosave(resolve_project, media_pool)
    local autosave_path = project.create_autosave_filename()
    local success, _ = project.save(autosave_path, resolve_project, media_pool)
    return success
end

return project