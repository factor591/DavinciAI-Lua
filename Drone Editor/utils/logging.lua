-- Improved Logging Module
-- Provides logging functionality with better path handling and permissions management

local logging = {}

-- Log levels
logging.DEBUG = 1
logging.INFO = 2
logging.WARNING = 3
logging.ERROR = 4
logging.CRITICAL = 5

local level_names = {
    [logging.DEBUG] = "DEBUG",
    [logging.INFO] = "INFO",
    [logging.WARNING] = "WARNING",
    [logging.ERROR] = "ERROR",
    [logging.CRITICAL] = "CRITICAL"
}

-- Module state
local state = {
    log_file = nil,
    log_level = logging.INFO,
    console_output = true,
    last_message = nil, -- For deduplication
    log_path = nil -- Store the log path for reference
}

-- Helper function to ensure directory exists
local function ensure_directory_exists(path)
    -- Extract directory from full path
    local directory = path:match("(.*[/\\])") or "./"
    
    -- Check if on Windows
    local is_windows = package.config:sub(1,1) == '\\'
    
    if is_windows then
        -- Windows approach
        -- First replace forward slashes with backslashes
        directory = directory:gsub("/", "\\")
        
        -- Try to create the directory using cmd.exe (quiet mode with /Q)
        os.execute('mkdir "' .. directory .. '" 2>nul')
    else
        -- Unix approach
        os.execute('mkdir -p "' .. directory .. '" 2>/dev/null')
    end
end

-- Get the user's documents directory (or fallback to temp)
local function get_user_documents()
    local home = os.getenv("USERPROFILE") or os.getenv("HOME")
    
    if home then
        if package.config:sub(1,1) == '\\' then
            -- Windows
            return home .. "\\Documents"
        else
            -- macOS/Linux
            return home .. "/Documents"
        end
    end
    
    -- Fallback to temp directory
    return os.getenv("TEMP") or os.getenv("TMP") or "/tmp"
end

-- Initialize the logging system
-- @param filename The log file to write to, or nil for automatic path
-- @param level Minimum log level (as string or number)
-- @param console Whether to output to console (default true)
function logging.init(filename, level, console)
    -- Close any existing log file
    if state.log_file then
        state.log_file:close()
        state.log_file = nil
    end
    
    -- Determine log path if not specified
    if not filename then
        local docs_dir = get_user_documents()
        filename = docs_dir .. "/DroneEditor/logs/drone_editor.log"
    end
    
    -- Store log path
    state.log_path = filename
    
    -- Ensure directory exists
    ensure_directory_exists(filename)
    
    -- Open new log file in append mode
    local file, err = io.open(filename, "a")
    if not file then
        print("ERROR: Could not open log file: " .. (err or "unknown error"))
        print("Will log to console only")
        state.log_file = nil
    else
        state.log_file = file
        -- Write a separator for new session
        file:write("\n\n--- New Session: " .. os.date("%Y-%m-%d %H:%M:%S") .. " ---\n\n")
        file:flush()
    end
    
    -- Set log level
    if type(level) == "string" then
        level = level:upper()
        if level == "DEBUG" then state.log_level = logging.DEBUG
        elseif level == "INFO" then state.log_level = logging.INFO
        elseif level == "WARNING" then state.log_level = logging.WARNING
        elseif level == "ERROR" then state.log_level = logging.ERROR
        elseif level == "CRITICAL" then state.log_level = logging.CRITICAL
        else
            print("WARNING: Unknown log level '" .. level .. "', defaulting to INFO")
            state.log_level = logging.INFO
        end
    elseif type(level) == "number" then
        if level >= logging.DEBUG and level <= logging.CRITICAL then
            state.log_level = level
        else
            print("WARNING: Invalid log level number, defaulting to INFO")
            state.log_level = logging.INFO
        end
    end
    
    -- Set console output flag
    state.console_output = console ~= false
    
    return state.log_file ~= nil
end

-- Format the current date and time
local function get_timestamp()
    local date_table = os.date("*t")
    return string.format("%04d-%02d-%02d %02d:%02d:%02d", 
        date_table.year, date_table.month, date_table.day,
        date_table.hour, date_table.min, date_table.sec)
end

-- Get the name of the calling function (for log context)
local function get_caller_info()
    local info = debug.getinfo(4, "Sln") -- Go up several levels to get the actual caller
    if info then
        local name = info.name or "unknown"
        return name
    end
    return "unknown"
end

-- Internal logging function
local function log(level, message)
    if level < state.log_level then
        return
    end
    
    -- Skip duplicate messages
    if message == state.last_message then
        return
    end
    
    state.last_message = message
    
    local timestamp = get_timestamp()
    local level_name = level_names[level] or "UNKNOWN"
    local caller = get_caller_info()
    local log_line = string.format("%s - %s - %s - %s", timestamp, level_name, caller, message)
    
    -- Write to log file
    if state.log_file then
        state.log_file:write(log_line .. "\n")
        state.log_file:flush()
    end
    
    -- Write to console if enabled
    if state.console_output then
        if level >= logging.WARNING then
            io.stderr:write(log_line .. "\n")
        else
            print(log_line)
        end
    end
end

-- Get current log file path
function logging.get_log_path()
    return state.log_path
end

-- Public logging functions
function logging.debug(message) log(logging.DEBUG, message) end
function logging.info(message) log(logging.INFO, message) end
function logging.warning(message) log(logging.WARNING, message) end
function logging.error(message) log(logging.ERROR, message) end
function logging.critical(message) log(logging.CRITICAL, message) end

-- Set the minimum log level
function logging.set_level(level)
    if type(level) == "string" then
        level = level:upper()
        if level == "DEBUG" then state.log_level = logging.DEBUG
        elseif level == "INFO" then state.log_level = logging.INFO
        elseif level == "WARNING" then state.log_level = logging.WARNING
        elseif level == "ERROR" then state.log_level = logging.ERROR
        elseif level == "CRITICAL" then state.log_level = logging.CRITICAL
        end
    elseif type(level) == "number" and level >= logging.DEBUG and level <= logging.CRITICAL then
        state.log_level = level
    end
end

-- Clean up logging (close file handles)
function logging.cleanup()
    if state.log_file then
        state.log_file:close()
        state.log_file = nil
    end
end

return logging