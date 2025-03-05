-- Media Pool Module
-- Handles media pool operations such as importing media

local logging = require("logging")

local mediapool = {}

-- Import media files into the media pool
-- @param media_pool MediaPool object
-- @param file_paths Table of file paths to import
-- @return Table of imported MediaPoolItem objects or nil on failure
function mediapool.import_media(media_pool, file_paths)
    if not media_pool then
        logging.error("Cannot import media: MediaPool object is nil")
        return nil
    end
    
    if not file_paths or #file_paths == 0 then
        logging.error("Cannot import media: No file paths provided")
        return nil
    end
    
    -- Filter out non-existent files
    local valid_paths = {}
    for _, path in ipairs(file_paths) do
        local file = io.open(path, "r")
        if file then
            file:close()
            table.insert(valid_paths, path)
        else
            logging.warning("File does not exist: " .. path)
        end
    end
    
    if #valid_paths == 0 then
        logging.error("No valid files to import")
        return nil
    end
    
    logging.info("Importing " .. #valid_paths .. " media files")
    
    -- Import the media files
    local new_items = media_pool:ImportMedia(valid_paths)
    
    if not new_items or #new_items == 0 then
        logging.error("Failed to import media files")
        return nil
    end
    
    logging.info("Successfully imported " .. #new_items .. " media files")
    
    -- Log the names of imported items
    for i, item in ipairs(new_items) do
        local name = "Unknown"
        
        -- Try to get the name of the item
        local success, result = pcall(function()
            if item.GetName and type(item.GetName) == "function" then
                return item:GetName()
            elseif item.GetClipProperty and type(item.GetClipProperty) == "function" then
                return item:GetClipProperty("Clip Name") or item:GetClipProperty("File Path")
            end
            return "Unknown"
        end)
        
        if success and result then
            name = result
        end
        
        logging.debug("Imported item " .. i .. ": " .. name)
    end
    
    return new_items
end

-- Create a new bin in the media pool
-- @param media_pool MediaPool object
-- @param name Name of the new bin
-- @param parent_bin Optional parent bin (default is root bin)
-- @return The new bin or nil on failure
function mediapool.create_bin(media_pool, name, parent_bin)
    if not media_pool then
        logging.error("Cannot create bin: MediaPool object is nil")
        return nil
    end
    
    if not name or name == "" then
        logging.error("Cannot create bin: No name provided")
        return nil
    end
    
    parent_bin = parent_bin or media_pool:GetRootFolder()
    
    logging.info("Creating bin '" .. name .. "'")
    
    local new_bin = media_pool:AddSubFolder(parent_bin, name)
    
    if not new_bin then
        logging.error("Failed to create bin '" .. name .. "'")
        return nil
    end
    
    logging.info("Successfully created bin '" .. name .. "'")
    return new_bin
end

-- Get or create a bin in the media pool
-- @param media_pool MediaPool object
-- @param name Name of the bin
-- @return The bin or nil on failure
function mediapool.get_or_create_bin(media_pool, name)
    if not media_pool then
        logging.error("Cannot get or create bin: MediaPool object is nil")
        return nil
    end
    
    if not name or name == "" then
        logging.error("Cannot get or create bin: No name provided")
        return nil
    end
    
    local root_bin = media_pool:GetRootFolder()
    if not root_bin then
        logging.error("Cannot get root folder")
        return nil
    end
    
    -- Check if bin already exists
    -- Unfortunately, there's no direct way to check if a bin exists by name
    -- We'd need to traverse the folder structure, but the API doesn't provide a way to list subfolders
    -- So we'll just try to create the bin and handle any error
    
    logging.info("Creating bin '" .. name .. "' (if it doesn't exist)")
    local new_bin = media_pool:AddSubFolder(root_bin, name)
    
    if not new_bin then
        logging.warning("Failed to create bin '" .. name .. "', it might already exist")
        -- We can't reliably get the existing bin by name without traversing the structure
        -- which isn't possible with the current API
        return nil
    end
    
    logging.info("Successfully created or found bin '" .. name .. "'")
    return new_bin
end

-- Get a media pool item by name
-- @param media_pool MediaPool object
-- @param name Name of the item to find
-- @return MediaPoolItem if found, nil otherwise
function mediapool.get_item_by_name(media_pool, name)
    if not media_pool or not name then
        return nil
    end
    
    -- Get all media pool items
    local root_folder = media_pool:GetRootFolder()
    if not root_folder then
        return nil
    end
    
    local clips = root_folder:GetClipList()
    if not clips then
        return nil
    end
    
    -- Search for the item by name
    for _, clip in ipairs(clips) do
        local clip_name = nil
        
        -- Try to get the name of the clip
        local success, result = pcall(function()
            if clip.GetName and type(clip.GetName) == "function" then
                return clip:GetName()
            elseif clip.GetClipProperty and type(clip.GetClipProperty) == "function" then
                return clip:GetClipProperty("Clip Name")
            end
            return nil
        end)
        
        if success and result then
            clip_name = result
        end
        
        if clip_name and clip_name == name then
            return clip
        end
    end
    
    return nil
end

-- Move a media pool item to a bin
-- @param media_pool MediaPool object
-- @param item MediaPoolItem to move
-- @param bin Bin to move the item to
-- @return true if successful, false otherwise
function mediapool.move_item_to_bin(media_pool, item, bin)
    if not media_pool or not item or not bin then
        logging.error("Cannot move item: Missing required parameters")
        return false
    end
    
    local success, result = pcall(function()
        return media_pool:MoveClips({item}, bin)
    end)
    
    if not success or not result then
        logging.error("Failed to move item to bin")
        return false
    end
    
    logging.info("Successfully moved item to bin")
    return true
end

return mediapool