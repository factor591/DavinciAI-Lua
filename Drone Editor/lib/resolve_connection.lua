-- Resolve Connection Module
-- Handles connection to DaVinci Resolve API with retry capability

local logging = require("logging")

local resolve_connection = {}

-- Initialize connection to DaVinci Resolve
-- @param retries Number of connection attempts (default 3)
-- @param delay Delay in seconds between retries (default 2)
-- @return Resolve object if successful, nil otherwise
function resolve_connection.init(retries, delay)
    retries = retries or 3
    delay = delay or 2
    
    local resolve = nil
    local attempt = 0
    
    -- First, check if bmd global is available
    if not bmd then
        logging.critical("bmd global not available. Make sure you're running this from within DaVinci Resolve.")
        return nil
    end
    
    while attempt < retries do
        attempt = attempt + 1
        
        -- Try to get Fusion
        local fusion = nil
        local success, result = pcall(function() return bmd.scriptapp("Fusion") end)
        
        if success and result then
            fusion = result
        else
            logging.warning("Attempt " .. attempt .. ": Failed to get Fusion: " .. tostring(result))
            
            -- Wait before trying again
            if attempt < retries then
                pcall(function() os.execute("sleep " .. delay) end)
            end
            
            -- Skip to next iteration without trying to get Resolve
            attempt = attempt + 1
            if attempt <= retries then
                logging.info("Retrying connection, attempt " .. attempt .. " of " .. retries)
            end
            -- Continue to next loop iteration
        end
        
        -- Only try to get Resolve if fusion was obtained
        if fusion then
            -- Try to get Resolve from Fusion
            success, result = pcall(function() return fusion:GetResolve() end)
            
            if success and result then
                resolve = result
                logging.info("Connected to DaVinci Resolve on attempt " .. attempt)
                return resolve
            else
                logging.warning("Attempt " .. attempt .. ": Failed to get Resolve: " .. tostring(result))
                
                -- Wait before trying again
                if attempt < retries then
                    pcall(function() os.execute("sleep " .. delay) end)
                end
            end
        end
    end
    
    logging.critical("Failed to connect to DaVinci Resolve after " .. retries .. " attempts.")
    return nil
end

-- Get operating system information
function resolve_connection.get_os_info()
    local os_name = "Unknown"
    
    if package.config:sub(1,1) == '\\' then
        os_name = "Windows"
    elseif os.execute('uname -s >/dev/null 2>&1') == 0 then
        local handle = io.popen('uname -s')
        if handle then
            local result = handle:read("*a")
            handle:close()
            result = result:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
            
            if result == "Darwin" then
                os_name = "macOS"
            elseif result == "Linux" then
                os_name = "Linux"
            else
                os_name = result
            end
        end
    end
    
    return os_name
end

-- Get DaVinci Resolve version
function resolve_connection.get_resolve_version(resolve)
    if not resolve then
        return "Unknown"
    end
    
    -- Try different methods to get version
    if resolve.GetVersionString and type(resolve.GetVersionString) == "function" then
        local success, version = pcall(function() return resolve:GetVersionString() end)
        if success then
            return version
        end
    end
    
    -- Try to detect version based on available methods
    local project_manager = resolve:GetProjectManager()
    if project_manager then
        local project = project_manager:GetCurrentProject()
        if project then
            -- Different versions expose different methods
            if project.GetSetting and type(project.GetSetting) == "function" then
                return "Unknown (has GetSetting)"
            elseif project.GetPresetList and type(project.GetPresetList) == "function" then
                return "Unknown (has GetPresetList)"
            elseif project.GetRenderFormats and type(project.GetRenderFormats) == "function" then
                return "Unknown (has GetRenderFormats)"
            end
        end
    end
    
    return "Unknown"
end

-- Check if a method exists in the Resolve API
function resolve_connection.method_exists(obj, method_name)
    if not obj then
        return false
    end
    
    return obj[method_name] ~= nil and type(obj[method_name]) == "function"
end

-- Safely call a method that might not exist in all Resolve versions
-- @param obj The object to call the method on
-- @param method_name The name of the method to call
-- @param ... Arguments to pass to the method
-- @return result, success (result of the call and boolean success flag)
function resolve_connection.safe_call(obj, method_name, ...)
    if not resolve_connection.method_exists(obj, method_name) then
        logging.info("Method " .. method_name .. " not available in this API version")
        return nil, false
    end
    
    local success, result = pcall(function(...)
        return obj[method_name](obj, ...)
    end, ...)
    
    if not success then
        logging.warning("Error calling " .. method_name .. ": " .. tostring(result))
        return nil, false
    end
    
    return result, true
end

-- Get feature support information
function resolve_connection.get_feature_support_info(project)
    if not project then
        return {}
    end
    
    local timeline = project:GetCurrentTimeline()
    local media_pool = project:GetMediaPool()
    
    local support_info = {
        ["Transitions"] = timeline and resolve_connection.method_exists(timeline, "AddTransition"),
        ["Timeline Item Removal"] = timeline and resolve_connection.method_exists(timeline, "RemoveItem"),
        ["Fusion Titles"] = timeline and resolve_connection.method_exists(timeline, "InsertFusionTitleIntoTimeline"),
        ["Fusion Generators"] = timeline and resolve_connection.method_exists(timeline, "InsertFusionGeneratorIntoTimeline"),
        ["Subtitles from Audio"] = timeline and resolve_connection.method_exists(timeline, "CreateSubtitlesFromAudio"),
        ["Media Duplication"] = media_pool and resolve_connection.method_exists(media_pool, "DuplicateMediaPoolItem"),
        ["Timeline Appending"] = media_pool and resolve_connection.method_exists(media_pool, "AppendToTimeline"),
        ["Audio Transcription"] = media_pool and resolve_connection.method_exists(media_pool, "TranscribeAudio")
    }
    
    return support_info
end

-- Log available feature support
function resolve_connection.log_feature_support(project)
    local support_info = resolve_connection.get_feature_support_info(project)
    
    for feature, supported in pairs(support_info) do
        logging.info(string.format("API Feature %s: %s", 
                                  feature, 
                                  supported and "Available" or "Not Available"))
    end
end

return resolve_connection