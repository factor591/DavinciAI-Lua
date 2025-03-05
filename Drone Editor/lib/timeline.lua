-- Timeline Module
-- Provides timeline manipulation functions

local logging = require("logging")
local resolve_connection = require("resolve_connection")

local timeline = {}

-- Create a timeline from media pool clips
-- @param project Current project
-- @param media_pool MediaPool object
-- @param clips Table of MediaPoolItem objects
-- @param name Optional name for the timeline (default "Drone Timeline")
-- @return Timeline object if successful, nil otherwise
function timeline.create_from_clips(project, media_pool, clips, name)
    if not project or not media_pool or not clips or #clips == 0 then
        logging.error("Cannot create timeline: Missing required parameters")
        return nil
    end
    
    name = name or "Drone Timeline"
    
    logging.info("Creating timeline '" .. name .. "' with " .. #clips .. " clips")
    
    local new_timeline = media_pool:CreateTimelineFromClips(name, clips)
    if not new_timeline then
        logging.error("Failed to create timeline")
        return nil
    end
    
    logging.info("Timeline created successfully")
    return new_timeline
end

-- Get the current timeline
-- @param project Current project
-- @return Timeline object if successful, nil otherwise
function timeline.get_current(project)
    if not project then
        logging.error("Cannot get current timeline: No project provided")
        return nil
    end
    
    local current_timeline = project:GetCurrentTimeline()
    if not current_timeline then
        logging.warning("No current timeline found")
        return nil
    end
    
    return current_timeline
end

-- Apply transitions between clips in a timeline
-- @param timeline_obj Timeline object
-- @param transition_type Type of transition (default "CrossDissolve")
-- @param duration Duration in frames (default 30)
-- @return true if successful, false otherwise
function timeline.apply_transitions(timeline_obj, transition_type, duration)
    if not timeline_obj then
        logging.error("Cannot apply transitions: No timeline provided")
        return false
    end
    
    transition_type = transition_type or "CrossDissolve"
    duration = duration or 30
    
    -- Check if the timeline has the required methods
    if not resolve_connection.method_exists(timeline_obj, "GetItemListInTrack") or
       not resolve_connection.method_exists(timeline_obj, "AddTransition") then
        logging.warning("Timeline does not support required methods for transitions")
        return false
    end
    
    local video_items = timeline_obj:GetItemListInTrack("video", 1)
    if not video_items or #video_items < 2 then
        logging.warning("Not enough video items in timeline to add transitions")
        return false
    end
    
    local success_count = 0
    local total_attempts = #video_items - 1
    
    for i = 1, #video_items - 1 do
        local success, result = pcall(function()
            return timeline_obj:AddTransition(transition_type, video_items[i], video_items[i+1], duration)
        end)
        
        if success and result then
            success_count = success_count + 1
        end
    end
    
    logging.info(string.format("Applied %d transitions (out of %d attempts)", success_count, total_attempts))
    return success_count > 0
end

-- Update a timeline with trimmed clips
-- @param project Current project
-- @param media_pool MediaPool object
-- @param timeline_obj Timeline object
-- @param new_clips Table of tables {clip, start_sec, end_sec}
-- @return true if successful, false otherwise
function timeline.update_with_trimmed_clips(project, media_pool, timeline_obj, new_clips)
    if not project or not media_pool or not timeline_obj or not new_clips or #new_clips == 0 then
        logging.error("Cannot update timeline: Missing required parameters")
        return false
    end
    
    -- Clear existing clips from timeline
    local video_items = timeline_obj:GetItemListInTrack("video", 1)
    if video_items and #video_items > 0 then
        logging.info("Clearing " .. #video_items .. " clips from timeline")
        
        for _, item in ipairs(video_items) do
            local success, result = resolve_connection.safe_call(timeline_obj, "RemoveItem", item)
            if not success then
                logging.warning("Failed to remove item from timeline")
            end
        end
    end
    
    -- Add the new clips to the timeline
    logging.info("Adding " .. #new_clips .. " trimmed clips to timeline")
    
    for _, clip_data in ipairs(new_clips) do
        local source_clip = clip_data[1]
        local start_sec = clip_data[2]
        local end_sec = clip_data[3]
        
        if source_clip and start_sec and end_sec then
            local clip_name = timeline.get_clip_name(source_clip)
            logging.info(string.format("Adding clip %s (%.2f to %.2f seconds)", clip_name, start_sec, end_sec))
            
            -- Try to duplicate the media pool item if supported
            local trimmed_clip = source_clip
            local success, new_clip = resolve_connection.safe_call(media_pool, "DuplicateMediaPoolItem", source_clip)
            if success and new_clip then
                trimmed_clip = new_clip
            end
            
            -- Set in and out points (not directly supported in Lua API, 
            -- would need to be handled when appending to timeline)
            
            -- Append the clip to the timeline
            local result, success = resolve_connection.safe_call(media_pool, "AppendToTimeline", {trimmed_clip})
            if not success then
                logging.warning("Failed to append clip to timeline")
            end
        else
            logging.warning("Invalid clip data provided")
        end
    end
    
    return true
end

-- Get the name of a clip
-- @param clip MediaPoolItem object
-- @return Clip name as string, or "Unknown" if not retrievable
function timeline.get_clip_name(clip)
    if not clip then
        return "Unknown"
    end
    
    -- Try different methods to get the clip name
    local name = nil
    
    -- Try GetClipProperty method
    if resolve_connection.method_exists(clip, "GetClipProperty") then
        for _, prop in ipairs({"File Path", "Clip Name", "Name"}) do
            local success, result = pcall(function()
                return clip:GetClipProperty(prop)
            end)
            
            if success and result then
                name = result
                break
            end
        end
    end
    
    -- Try GetName method
    if not name and resolve_connection.method_exists(clip, "GetName") then
        local success, result = pcall(function()
            return clip:GetName()
        end)
        
        if success and result then
            name = result
        end
    end
    
    return name or "Unknown"
end

-- Convert seconds to timecode
-- @param seconds Number of seconds
-- @param fps Frames per second (default 30)
-- @return Timecode string in format "HH:MM:SS:FF"
function timeline.seconds_to_timecode(seconds, fps)
    fps = fps or 30
    
    local frames = math.floor(seconds * fps + 0.5)
    local h = math.floor(frames / (fps * 3600))
    frames = frames % (fps * 3600)
    local m = math.floor(frames / (fps * 60))
    frames = frames % (fps * 60)
    local s = math.floor(frames / fps)
    local f = frames % fps
    
    return string.format("%02d:%02d:%02d:%02d", h, m, s, f)
end

-- Convert timecode to seconds
-- @param timecode Timecode string in format "HH:MM:SS:FF"
-- @param fps Frames per second (default 30)
-- @return Number of seconds
function timeline.timecode_to_seconds(timecode, fps)
    fps = fps or 30
    
    local h, m, s, f = timecode:match("(%d+):(%d+):(%d+):(%d+)")
    if not h then
        h, m, s = timecode:match("(%d+):(%d+):(%d+)")
        f = 0
    end
    
    if not h then
        return 0
    end
    
    h, m, s, f = tonumber(h), tonumber(m), tonumber(s), tonumber(f or 0)
    return h * 3600 + m * 60 + s + f / fps
end

return timeline