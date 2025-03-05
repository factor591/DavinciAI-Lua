-- Default Settings Module
-- Defines default settings for the application

local settings = {
    -- AI processing settings
    ai_processing_level = "Medium", -- "Low", "Medium", "High"
    
    -- Color grading settings
    lut_selection = "Default", -- "Default", "Cinematic", "Vintage", "Drone Aerial"
    
    -- Export settings
    export_resolution = "1080p", -- "1080p", "4K", "8K" or custom table {width=X, height=Y}
    export_format = "MP4", -- "MP4", "MOV", "AVI", "ProRes", "H.265"
    
    -- Audio settings
    auto_volume = false, -- Enable automatic volume balancing
    noise_gate_eq = false, -- Enable noise gate and EQ adjustments
    music_selection = "None", -- "None", "Track 1", "Track 2", "Track 3"
    
    -- Timeline settings
    default_transition = "Cross Dissolve",
    default_transition_duration = 30, -- frames
    
    -- UI settings
    show_tooltips = true,
    confirm_deletions = true,
    
    -- Logging settings
    log_level = "INFO", -- "DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"
    
    -- Path settings
    lut_paths = {
        -- Windows paths
        os.getenv("USERPROFILE") and os.getenv("USERPROFILE") .. "\\Documents\\Blackmagic Design\\DaVinci Resolve\\LUT",
        "C:\\ProgramData\\Blackmagic Design\\DaVinci Resolve\\Support\\LUT",
        
        -- macOS paths
        os.getenv("HOME") and os.getenv("HOME") .. "/Library/Application Support/Blackmagic Design/DaVinci Resolve/LUT",
        "/Library/Application Support/Blackmagic Design/DaVinci Resolve/LUT",
        
        -- Linux paths
        os.getenv("HOME") and os.getenv("HOME") .. "/.local/share/DaVinciResolve/LUT",
        "/opt/resolve/LUT"
    },
    
    -- LUT name mapping
    lut_name_map = {
        ["Default"] = "Default.cube",
        ["Cinematic"] = "Film Look.cube",
        ["Vintage"] = "Vintage Film.cube",
        ["Drone Aerial"] = "Aerial.cube"
    }
}

-- Function to save settings to a file
function settings.save(filepath)
    filepath = filepath or "drone_editor_settings.json"
    
    -- Create a copy of the settings to save
    local settings_to_save = {}
    for k, v in pairs(settings) do
        if type(v) ~= "function" then
            settings_to_save[k] = v
        end
    end
    
    -- Convert to JSON
    local json_str = require("json").encode(settings_to_save)
    
    -- Write to file
    local file, err = io.open(filepath, "w")
    if not file then
        return false, "Could not open file: " .. (err or "unknown error")
    end
    
    file:write(json_str)
    file:close()
    
    return true
end

-- Function to load settings from a file
function settings.load(filepath)
    filepath = filepath or "drone_editor_settings.json"
    
    -- Check if file exists
    local file = io.open(filepath, "r")
    if not file then
        return false, "File not found"
    end
    
    -- Read the file
    local content = file:read("*all")
    file:close()
    
    if not content or content == "" then
        return false, "Empty file"
    end
    
    -- Parse JSON
    local success, loaded_settings = pcall(function()
        return require("json").decode(content)
    end)
    
    if not success or not loaded_settings then
        return false, "Invalid JSON"
    end
    
    -- Update settings
    for k, v in pairs(loaded_settings) do
        if settings[k] ~= nil and type(settings[k]) ~= "function" then
            settings[k] = v
        end
    end
    
    return true
end

-- Function to get a setting value
function settings.get(key, default)
    if settings[key] ~= nil then
        return settings[key]
    end
    return default
end

-- Function to set a setting value
function settings.set(key, value)
    if key and key ~= "" and key ~= "save" and key ~= "load" and key ~= "get" and key ~= "set" then
        settings[key] = value
        return true
    end
    return false
end

return settings