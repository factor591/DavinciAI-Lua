-- Color Grading Module
-- Handles color grading operations such as LUT application

local logging = require("logging")
local timeline = require("timeline")

local color = {}

-- Apply a LUT to all clips in the current timeline
-- @param project Current project
-- @param lut_path Path to the LUT file
-- @return true if successful, false otherwise
function color.apply_lut(project, lut_path)
    if not project then
        logging.error("Cannot apply LUT: No project provided")
        return false
    end
    
    if not lut_path then
        logging.error("Cannot apply LUT: No LUT path provided")
        return false
    end
    
    -- Check if the LUT file exists
    local file = io.open(lut_path, "r")
    if not file then
        logging.error("LUT file does not exist: " .. lut_path)
        return false
    end
    file:close()
    
    -- Get the current timeline
    local current_timeline = project:GetCurrentTimeline()
    if not current_timeline then
        logging.warning("No current timeline found")
        return false
    end
    
    -- Get all video clips in the timeline
    local video_items = current_timeline:GetItemListInTrack("video", 1)
    if not video_items or #video_items == 0 then
        logging.warning("No video items in timeline")
        return false
    end
    
    -- Apply the LUT to each clip
    local success_count = 0
    for _, item in ipairs(video_items) do
        local success, result = pcall(function()
            return item:ApplyLUT(lut_path)
        end)
        
        if success and result then
            success_count = success_count + 1
        end
    end
    
    logging.info(string.format("Applied LUT to %d of %d clips", success_count, #video_items))
    return success_count > 0
end

-- Get the path to a LUT by name
-- @param lut_name Name of the LUT (without extension)
-- @return Path to the LUT file or nil if not found
function color.get_lut_path(lut_name)
    if not lut_name or lut_name == "" then
        logging.error("Cannot get LUT path: No LUT name provided")
        return nil
    end
    
    -- Define LUT directories based on operating system
    local lut_directories = {}
    
    -- Get the OS type
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
    
    -- Set directories based on OS
    if os_name == "windows" then
        -- Windows paths
        table.insert(lut_directories, os.getenv("USERPROFILE") .. "\\Documents\\Blackmagic Design\\DaVinci Resolve\\LUT")
        table.insert(lut_directories, "C:\\ProgramData\\Blackmagic Design\\DaVinci Resolve\\Support\\LUT")
    elseif os_name == "macos" then
        -- macOS paths
        table.insert(lut_directories, os.getenv("HOME") .. "/Library/Application Support/Blackmagic Design/DaVinci Resolve/LUT")
        table.insert(lut_directories, "/Library/Application Support/Blackmagic Design/DaVinci Resolve/LUT")
    elseif os_name == "linux" then
        -- Linux paths
        table.insert(lut_directories, os.getenv("HOME") .. "/.local/share/DaVinciResolve/LUT")
        table.insert(lut_directories, "/opt/resolve/LUT")
    end
    
    -- Map of common LUT names to filenames
    local lut_names = {
        ["Default"] = "Default.cube",
        ["Cinematic"] = "Film Look.cube",
        ["Vintage"] = "Vintage Film.cube"
    }
    
    -- Get the filename for the requested LUT
    local filename = lut_names[lut_name]
    if not filename then
        -- If not in our map, append .cube extension
        filename = lut_name .. ".cube"
    end
    
    -- Search for the LUT in the directories
    for _, directory in ipairs(lut_directories) do
        local path = directory .. "/" .. filename
        path = path:gsub("/", package.config:sub(1,1)) -- Replace with correct path separator
        
        local file = io.open(path, "r")
        if file then
            file:close()
            logging.info("Found LUT at: " .. path)
            return path
        end
    end
    
    logging.warning("LUT not found: " .. lut_name)
    return nil
end

-- Apply auto color correction to clips in the timeline
-- @param project Current project
-- @return true if successful, false otherwise
function color.auto_color_correction(project)
    if not project then
        logging.error("Cannot apply auto color correction: No project provided")
        return false
    end
    
    -- Get the current timeline
    local current_timeline = project:GetCurrentTimeline()
    if not current_timeline then
        logging.warning("No current timeline found")
        return false
    end
    
    -- Get all video clips in the timeline
    local video_items = current_timeline:GetItemListInTrack("video", 1)
    if not video_items or #video_items == 0 then
        logging.warning("No video items in timeline")
        return false
    end
    
    -- Apply auto color correction to each clip
    local success_count = 0
    for _, item in ipairs(video_items) do
        -- Get the clip color properties
        local success, color_props = pcall(function()
            -- Open the clip in the Color page
            project:SetCurrentTimeline(current_timeline)
            current_timeline:SetCurrentClip(item)
            
            -- Get the current page
            local prev_page = project:GetCurrentPage()
            
            -- Switch to Color page
            project:SetCurrentPage("Color")
            
            -- Apply auto color correction
            -- Note: This is a hypothetical function, as the actual Resolve API doesn't expose this directly
            -- In a real implementation, we might need to use alternative approaches
            local result = false
            if item.AutoColorAdjust and type(item.AutoColorAdjust) == "function" then
                result = item:AutoColorAdjust()
            elseif current_timeline.AutoColorAdjustCurrentClip and type(current_timeline.AutoColorAdjustCurrentClip) == "function" then
                result = current_timeline:AutoColorAdjustCurrentClip()
            end
            
            -- Switch back to the previous page
            project:SetCurrentPage(prev_page)
            
            return result
        end)
        
        if success and color_props then
            success_count = success_count + 1
        end
    end
    
    logging.info(string.format("Applied auto color correction to %d of %d clips", success_count, #video_items))
    return success_count > 0
end

-- Apply a color preset to clips in the timeline
-- @param project Current project
-- @param preset_name Name of the preset to apply
-- @return true if successful, false otherwise
function color.apply_preset(project, preset_name)
    if not project or not preset_name then
        logging.error("Cannot apply color preset: Missing required parameters")
        return false
    end
    
    -- Get the current timeline
    local current_timeline = project:GetCurrentTimeline()
    if not current_timeline then
        logging.warning("No current timeline found")
        return false
    end
    
    -- Get all video clips in the timeline
    local video_items = current_timeline:GetItemListInTrack("video", 1)
    if not video_items or #video_items == 0 then
        logging.warning("No video items in timeline")
        return false
    end
    
    -- Apply preset based on name
    local preset_applied = false
    
    if preset_name == "Cinematic" then
        -- Apply cinematic look
        local lut_path = color.get_lut_path("Cinematic")
        if lut_path then
            preset_applied = color.apply_lut(project, lut_path)
        else
            logging.warning("Cinematic LUT not found")
        end
    elseif preset_name == "Vintage" then
        -- Apply vintage look
        local lut_path = color.get_lut_path("Vintage")
        if lut_path then
            preset_applied = color.apply_lut(project, lut_path)
        else
            logging.warning("Vintage LUT not found")
        end
    elseif preset_name == "Drone Aerial" then
        -- Apply drone aerial look (could be a custom LUT or settings)
        local lut_path = color.get_lut_path("Drone")
        if lut_path then
            preset_applied = color.apply_lut(project, lut_path)
        else
            logging.warning("Drone LUT not found")
            -- Apply some default settings instead
            preset_applied = color.auto_color_correction(project)
        end
    else
        logging.warning("Unknown preset: " .. preset_name)
    end
    
    return preset_applied
end

return color