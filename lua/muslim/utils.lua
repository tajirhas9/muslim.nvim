local M = {}
local MS = 1
local SECOND = 1000 * MS
local MINUTE = 60 * SECOND
local HOUR = 60 * MINUTE


M.default_timezone = function()
    return os.date("%Z") or "UTC"
end

M.is_date_table = function(v)
    if type(v) == "table" then
        return v.year ~= nil and v.month ~= nil and v.day ~= nil
    end
    return false
end

M.value = function(str)
    str = tostring(str or "")
    local num = str:match("[-+]?[0-9]*%.?[0-9]+")
    if num then return tonumber(num) end
    return 0
end

M.is_min = function(str)
    return tostring(str or ""):find("min") ~= nil
end

local time_to_string = function(timestamp, utc_offset, format)
    local offsetMinutes = 0
    if utc_offset ~= "auto" and type(utc_offset) == "number" then
        offsetMinutes = utc_offset
    end
    -- compute seconds value adjusted by utc_offset (minutes)
    local seconds = math.floor(timestamp / 1000) + (offsetMinutes * 60)
    -- use UTC time to format
    local t = os.date("!*t", seconds)
    local hour = t.hour
    local min = t.min
    if format == "24h" then
        return string.format("%02d:%02d", hour, min)
    elseif format == "12h" or format == "12H" then
        local am = hour < 12
        local h12 = hour % 12
        if h12 == 0 then h12 = 12 end
        if format == "12H" then
            local suffix = am and " AM" or " PM"
            return string.format("%02d:%02d%s", h12, min, suffix)
        else
            local suffix = am and " AM" or " PM"
            -- JS 12h uses numeric hour without leading zero, keep that behaviour
            return string.format("%d:%02d%s", h12, min, suffix)
        end
    else
        -- fallback to 24h
        return string.format("%02d:%02d", hour, min)
    end
end

M.format_time = function(timestamp, utc_offset, format)
    local fmt = format
    local InvalidTime = "-----"
    if type(timestamp) ~= "number" or timestamp ~= timestamp then
        return InvalidTime
    end
    if type(fmt) == "function" then
        return fmt(timestamp)
    end
    local fmtLower = tostring(fmt):lower()
    if fmtLower == "x" then
        return math.floor(timestamp / ((fmt == "X") and 1000 or 1))
    end
    return time_to_string(timestamp, utc_offset, fmt)
end

M.to_fixed = function(number, decimals)
    return string.format("%02." .. decimals .. "f", number)
end

local get_waqt_label = function(waqt)
    local labels = {
        fajr = 'Fajr',
        dhuhr = 'Dhuhr',
        asr = 'Asr',
        maghrib = 'Maghrib',
        isha = 'Isha'
    }

    return labels[waqt]
end

M.format = function(waqt_info, utc_offset)
    utc_offset = utc_offset or 0
    local cur_waqt = waqt_info.waqt_name
    local next_waqt = waqt_info.next_waqt_name
    local next_start = M.format_time(waqt_info.next_waqt_start, utc_offset * 60)
    if cur_waqt then
        local cur_end_h = M.to_fixed(math.floor(waqt_info.time_left / HOUR), 0)
        local cur_end_m = M.to_fixed(math.floor((waqt_info.time_left % HOUR) / MINUTE), 0)
        return string.format('%s ends in %s:%s | %s at: %s', get_waqt_label(cur_waqt), cur_end_h, cur_end_m,
            get_waqt_label(next_waqt),
            next_start)
    else
        return string.format('%s at: %s', get_waqt_label(next_waqt), next_start)
    end
end

M.get_warning_level = function(waqt_info, utc_offset)
    local colors = {
        green = '#008000',
        red = '#ff2c2c',
        orange = '#ffa500'
    }
    local cur_end_h = math.floor(waqt_info.time_left / HOUR)
    local cur_end_m = math.floor((waqt_info.time_left % HOUR) / MINUTE)

    -- print(waqt_info.time_left, cur_end_h, cur_end_m)

    if cur_end_h >= 1 then
        return { fg = colors.green }
    elseif cur_end_m < 30 then
        return { fg = colors.red }
    else
        return { fg = colors.orange }
    end
end

return M
