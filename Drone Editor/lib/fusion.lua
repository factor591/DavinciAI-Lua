-- Fusion Module
-- Handles Fusion effects automation

local logging = require("logging")
local resolve_connection = require("resolve_connection")

local fusion = {}

-- Initialize Fusion
-- @param resolve Resolve object
-- @return Fusion object if successful, nil otherwise
function fusion.init(resolve)
    if not resolve then
        logging.error("Cannot initialize Fusion: No Resolve object provided")
        return nil
    end
    
    logging.info("Initializing Fusion")
    
    local fusion_obj = nil
    
    -- Try to get Fusion from Resolve
    local success, result = pcall(function()
        return resolve:GetFusion()
    end)
    
    if success and result then
        fusion_obj = result
        logging.info("Successfully initialized Fusion")
    else
        logging.error("Failed to initialize Fusion")
    end
    
    return fusion_obj
end

-- Create a fusion composition
-- @param project Current project
-- @param timeline_obj Timeline object
-- @param clip_index Index of the clip to add the composition to (default is current clip)
-- @return Composition object if successful, nil otherwise
function fusion.create_composition(project, timeline_obj, clip_index)
    if not project or not timeline_obj then
        logging.error("Cannot create composition: Missing required parameters")
        return nil
    end
    
    -- Get clips in the timeline
    local video_items = timeline_obj:GetItemListInTrack("video", 1)
    if not video_items or #video_items == 0 then
        logging.warning("No video items in timeline")
        return nil
    end
    
    -- Determine which clip to use
    local clip = nil
    if clip_index and clip_index > 0 and clip_index <= #video_items then
        clip = video_items[clip_index]
    else
        -- Use the current clip
        clip = timeline_obj:GetCurrentVideoItem()
    end
    
    if not clip then
        logging.warning("No clip selected for Fusion composition")
        return nil
    end
    
    -- Switch to Fusion page
    local prev_page = project:GetCurrentPage()
    project:SetCurrentPage("Fusion")
    
    -- Create the composition
    local comp = nil
    local success, result = pcall(function()
        return project:GetCurrentTimeline():GetCurrentClip():GetFusionCompManager():GetCompByIndex(1)
    end)
    
    if success and result then
        comp = result
        logging.info("Successfully created Fusion composition")
    else
        logging.error("Failed to create Fusion composition")
    end
    
    -- Switch back to the previous page
    project:SetCurrentPage(prev_page)
    
    return comp
end

-- Add a title to the timeline using Fusion
-- @param project Current project
-- @param timeline_obj Timeline object
-- @param title_text Text for the title
-- @param title_style Style of the title (e.g., "Simple", "Lower Third")
-- @param duration Duration in frames (default 90)
-- @return true if successful, false otherwise
function fusion.add_title(project, timeline_obj, title_text, title_style, duration)
    if not project or not timeline_obj or not title_text then
        logging.error("Cannot add title: Missing required parameters")
        return false
    end
    
    title_style = title_style or "Simple"
    duration = duration or 90
    
    -- Check if the required method is available
    if not resolve_connection.method_exists(timeline_obj, "InsertFusionTitleIntoTimeline") then
        logging.warning("InsertFusionTitleIntoTimeline method not available in this API version")
        return false
    end
    
    -- Insert the title
    logging.info(string.format("Adding %s title: '%s'", title_style, title_text))
    
    local success, result = pcall(function()
        return timeline_obj:InsertFusionTitleIntoTimeline(title_text)
    end)
    
    if success and result then
        logging.info("Successfully added title")
        
        -- Try to set the duration of the title
        local title_item = timeline_obj:GetCurrentVideoItem()
        if title_item then
            local success, result = pcall(function()
                return title_item:SetProperty("Duration", duration)
            end)
            
            if not success or not result then
                logging.warning("Failed to set title duration")
            end
        end
        
        return true
    else
        logging.error("Failed to add title")
        return false
    end
end

-- Add a transition effect using Fusion
-- @param project Current project
-- @param timeline_obj Timeline object
-- @param clip1 First clip (TimelineItem)
-- @param clip2 Second clip (TimelineItem)
-- @param effect_name Name of the effect (default "Cross Dissolve")
-- @param duration Duration in frames (default 30)
-- @return true if successful, false otherwise
function fusion.add_transition_effect(project, timeline_obj, clip1, clip2, effect_name, duration)
    if not project or not timeline_obj or not clip1 or not clip2 then
        logging.error("Cannot add transition effect: Missing required parameters")
        return false
    end
    
    effect_name = effect_name or "Cross Dissolve"
    duration = duration or 30
    
    -- Check if the required method is available
    if not resolve_connection.method_exists(timeline_obj, "AddTransition") then
        logging.warning("AddTransition method not available in this API version")
        return false
    end
    
    -- Add the transition
    logging.info(string.format("Adding %s transition between clips", effect_name))
    
    local success, result = pcall(function()
        return timeline_obj:AddTransition(effect_name, clip1, clip2, duration)
    end)
    
    if success and result then
        logging.info("Successfully added transition effect")
        return true
    else
        logging.error("Failed to add transition effect")
        return false
    end
end

-- Add a visual effect to a clip using Fusion
-- @param project Current project
-- @param timeline_obj Timeline object
-- @param clip Clip to add the effect to (TimelineItem)
-- @param effect_name Name of the effect
-- @return true if successful, false otherwise
function fusion.add_visual_effect(project, timeline_obj, clip, effect_name)
    if not project or not timeline_obj or not clip or not effect_name then
        logging.error("Cannot add visual effect: Missing required parameters")
        return false
    end
    
    -- Switch to Fusion page
    local prev_page = project:GetCurrentPage()
    project:SetCurrentPage("Fusion")
    
    -- Select the clip
    timeline_obj:SetCurrentVideoItem(clip)
    
    -- Create a Fusion composition
    local comp = nil
    local success, result = pcall(function()
        return timeline_obj:GetCurrentClip():GetFusionCompManager():GetCompByIndex(1)
    end)
    
    if success and result then
        comp = result
        logging.info("Got Fusion composition")
    else
        logging.error("Failed to get Fusion composition")
        project:SetCurrentPage(prev_page)
        return false
    end
    
    -- Add the effect based on name
    local effect_added = false
    
    if effect_name == "Glow" then
        -- Add a glow effect
        success, result = pcall(function()
            local tool = comp:AddTool("Glow")
            tool:SetInput("Blend", 0.5)
            tool:SetInput("Glow", 0.4)
            return tool
        end)
        effect_added = success and result ~= nil
    elseif effect_name == "ColorCorrector" then
        -- Add a color corrector
        success, result = pcall(function()
            local tool = comp:AddTool("ColorCorrector")
            tool:SetInput("SaturationGain", 1.2)
            tool:SetInput("ContrastGain", 1.1)
            return tool
        end)
        effect_added = success and result ~= nil
    elseif effect_name == "Blur" then
        -- Add a blur effect
        success, result = pcall(function()
            local tool = comp:AddTool("Blur")
            tool:SetInput("XBlurSize", 3.0)
            tool:SetInput("YBlurSize", 3.0)
            return tool
        end)
        effect_added = success and result ~= nil
    else
        -- Try to add the effect by name
        success, result = pcall(function()
            return comp:AddTool(effect_name)
        end)
        effect_added = success and result ~= nil
    end
    
    -- Save the composition
    if effect_added then
        success, result = pcall(function()
            return comp:Save()
        end)
        
        if not success or not result then
            logging.warning("Failed to save Fusion composition")
        end
    end
    
    -- Switch back to the previous page
    project:SetCurrentPage(prev_page)
    
    if effect_added then
        logging.info("Successfully added " .. effect_name .. " effect")
        return true
    else
        logging.error("Failed to add " .. effect_name .. " effect")
        return false
    end
end

-- Create a text generator
-- @param project Current project
-- @param timeline_obj Timeline object
-- @param text Text to display
-- @param position Position of the text ("Lower Third", "Center", "Top", "Custom")
-- @param duration Duration in frames (default 90)
-- @return true if successful, false otherwise
function fusion.create_text_generator(project, timeline_obj, text, position, duration)
    if not project or not timeline_obj or not text then
        logging.error("Cannot create text generator: Missing required parameters")
        return false
    end
    
    position = position or "Lower Third"
    duration = duration or 90
    
    -- Check if the required method is available
    if not resolve_connection.method_exists(timeline_obj, "InsertFusionGeneratorIntoTimeline") then
        logging.warning("InsertFusionGeneratorIntoTimeline method not available in this API version")
        return false
    end
    
    -- Insert the text generator
    logging.info(string.format("Creating text generator: '%s'", text))
    
    local success, result = pcall(function()
        return timeline_obj:InsertFusionGeneratorIntoTimeline("Text+")
    end)
    
    if success and result then
        logging.info("Successfully created text generator")
        
        -- Now we need to configure the text
        local text_clip = timeline_obj:GetCurrentVideoItem()
        if text_clip then
            -- Switch to Fusion page
            local prev_page = project:GetCurrentPage()
            project:SetCurrentPage("Fusion")
            
            -- Get the Fusion composition
            local comp = nil
            success, result = pcall(function()
                return timeline_obj:GetCurrentClip():GetFusionCompManager():GetCompByIndex(1)
            end)
            
            if success and result then
                comp = result
                
                -- Find the text tool
                local text_tool = nil
                success, result = pcall(function()
                    return comp:FindTool("Text1")
                end)
                
                if success and result then
                    text_tool = result
                    
                    -- Set the text
                    text_tool:SetInput("StyledText", text)
                    
                    -- Set the position based on the specified position
                    if position == "Lower Third" then
                        text_tool:SetInput("Center", {0.5, 0.8})
                    elseif position == "Center" then
                        text_tool:SetInput("Center", {0.5, 0.5})
                    elseif position == "Top" then
                        text_tool:SetInput("Center", {0.5, 0.2})
                    end
                    
                    -- Save the composition
                    comp:Save()
                else
                    logging.warning("Failed to find the text tool")
                end
            else
                logging.warning("Failed to get Fusion composition")
            end
            
            -- Set the duration of the text generator
            success, result = pcall(function()
                return text_clip:SetProperty("Duration", duration)
            end)
            
            if not success or not result then
                logging.warning("Failed to set text generator duration")
            end
            
            -- Switch back to the previous page
            project:SetCurrentPage(prev_page)
        else
            logging.warning("Failed to get the text generator clip")
        end
        
        return true
    else
        logging.error("Failed to create text generator")
        return false
    end
end

-- Run a complete Fusion automation sequence
-- @param project Current project
-- @return true if successful, false otherwise
function fusion.run_automation(project)
    if not project then
        logging.error("Cannot run Fusion automation: No project provided")
        return false
    end
    
    -- Get the current timeline
    local timeline_obj = project:GetCurrentTimeline()
    if not timeline_obj then
        logging.warning("No current timeline found")
        return false
    end
    
    -- Get all video clips in the timeline
    local video_items = timeline_obj:GetItemListInTrack("video", 1)
    if not video_items or #video_items == 0 then
        logging.warning("No video items in timeline")
        return false
    end
    
    -- Apply transitions between clips
    local transitions_applied = 0
    for i = 1, #video_items - 1 do
        local success = fusion.add_transition_effect(project, timeline_obj, video_items[i], video_items[i+1])
        if success then
            transitions_applied = transitions_applied + 1
        end
    end
    
    logging.info(string.format("Applied %d transitions", transitions_applied))
    
    -- Add a title at the beginning
    local title_added = fusion.add_title(project, timeline_obj, "Drone Footage", "Simple")
    
    -- Add visual effects to some clips
    local effects_applied = 0
    for i, clip in ipairs(video_items) do
        -- Apply an effect to every other clip
        if i % 2 == 0 then
            local effect_name = "Blur"
            if i % 4 == 0 then
                effect_name = "Glow"
            end
            
            local success = fusion.add_visual_effect(project, timeline_obj, clip, effect_name)
            if success then
                effects_applied = effects_applied + 1
            end
        end
    end
    
    logging.info(string.format("Applied %d visual effects", effects_applied))
    
    -- Add a text generator at the end
    local text_added = fusion.create_text_generator(project, timeline_obj, "Thanks for watching!", "Center")
    
    return transitions_applied > 0 or title_added or effects_applied > 0 or text_added
end

return fusion