lua
-- fairlight_audio.lua

local logging = require("logging")

local fairlight_audio = {}

-- Normalizes the volume of a specific audio track
-- @param timeline_obj DaVinci Resolve Timeline object
-- @param track_index The index of the audio track to normalize (1-based)
-- @return true if successful, false otherwise
function fairlight_audio.normalize_track_volume(timeline_obj, track_index)
    if not timeline_obj then
        logging.error("Cannot normalize track volume: No timeline object provided")
        return false
    end

    if not track_index or type(track_index) ~= "number" or track_index < 1 then
        logging.error("Invalid track index: " .. tostring(track_index))
        return false
    end

     local track_type = "audio"
     local current_volume = timeline_obj:GetTrackVolume(track_type, track_index)
     
     if current_volume == nil then
         logging.error("Failed to get current volume for track " .. track_index)
         return false
     end

     logging.info("Current volume for track " .. track_index .. ": " .. current_volume .. " dB")

     -- Basic peak normalization (adjust to target -1 dBFS)
     local target_peak = -1
     local gain_adjustment = target_peak - current_volume
     local new_volume = current_volume + gain_adjustment

     logging.info("Normalizing track " .. track_index .. " by " .. gain_adjustment .. " dB")

     local success, result = pcall(function()
        timeline_obj:SetTrackVolume(track_type, track_index, new_volume)
    end)

     if success then
         logging.info("Successfully normalized track " .. track_index .. ". Old Volume: " .. current_volume .. " dB, New Volume: " .. new_volume .. " dB")
         return true
    else
        logging.error("Failed to normalize track " .. track_index .. ": " .. tostring(result))
        return false
    end
end

-- Applies noise reduction to a specific audio track
-- @param timeline_obj DaVinci Resolve Timeline object
-- @param track_index The index of the audio track to apply noise reduction to (1-based)
-- @return true if successful, false otherwise
function fairlight_audio.apply_noise_reduction(timeline_obj, track_index)
    if not timeline_obj then
        logging.error("Cannot apply noise reduction: No timeline object provided")
        return false
    end

    if not track_index or type(track_index) ~= "number" or track_index < 1 then
        logging.error("Invalid track index: " .. tostring(track_index))
        return false
    end

    local track_type = "audio"-- Applies noise reduction to a specific audio track
-- @param timeline_obj DaVinci Resolve Timeline object
-- @param track_index The index of the audio track to apply noise reduction to (1-based)
-- @return true if successful, false otherwise
function fairlight_audio.apply_noise_reduction(timeline_obj, track_index)
   if not timeline_obj then
        logging.error("Cannot apply noise reduction: No timeline object provided")
        return false
    end

    if not track_index or type(track_index) ~= "number" or track_index < 1 then
        logging.error("Invalid track index: " .. tostring(track_index))
        return false
    end

    local effect_name = "Noise Reduction"
    local success, result = pcall(timeline_obj.AddTrackEffect, timeline_obj, track_type, track_index, effect_name)
    if not success then
        logging.error("Failed to add '" .. effect_name .. "' effect to track " .. track_index .. ": " .. tostring(result))
    return false
    end
    logging.info("Successfully applied noise reduction to track " .. track_index)
    return true
end

return fairlight_audio