local Job = require("plenary.job")

local function _encode_uri_char(char)
    return string.format('%%%02X', string.byte(char))
end

local function encode_uri(uri)
    return (uri:gsub("[^%w%-%_%.%~%!;/%?:@&=+$,#]", _encode_uri_char))
end

local fetch_async = function(config, callback)
    local url = string.format(
        "%s/%s?latitude=%s&longitude=%s&method=%s&shafaq=general&tune=%s&school=%s&timezonestring=%s&calendarMethod=UAQ",
        config.api_url,
        os.date('%d-%m-%Y'),
        config.latitude,
        config.longitude,
        config.method,
        encode_uri('5,3,5,7,9,-1,0,8,-6'),
        config.school,
        encode_uri(config.timezone)
    )

    print("url", url)
    Job:new({
        command = "curl",
        args = { "-s", url },
        on_exit = function(j)
            local result = table.concat(j:result(), "\n")
            callback(result)
        end,
    }):start()
end

-- FORMATTER: compute time left
local function time_left(next_time)
    local h, m = next_time:match("(%d+):(%d+)")
    if not h or not m then return nil end

    local target = os.date('*t')
    target.hour = h
    target.min = m
    local now_sec = os.time()
    local target_sec = os.time(target)

    local diff = os.difftime(target_sec, now_sec)

    local diff_min = math.floor(diff / 60)
    local diff_hr = math.floor(diff_min / 60)
    diff_min = diff_min % 60

    return diff_hr, diff_min
end

-- Which prayer is next?
local function compute_next(t)
    local order = { "Fajr", "Dhuhr", "Asr", "Maghrib", "Isha" }
    for _, p in ipairs(order) do
        local hr, min = time_left(t[p])
        if hr >= 0 and min > 0 then
            return p, hr, min
        end
    end
end

local function colorize(text, urgent)
    if urgent then
        return "%#ErrorMsg#" .. text .. "%*"
    end
    return text
end

local format_output = function(json)
    local ok, data = pcall(vim.json.decode, json)
    if not ok or not data or not data.data or not data.data.timings then
        return "Prayer: error"
    end

    local t = data.data.timings
    local next_prayer, hr, min = compute_next(t)

    if not next_prayer then
        return "Prayer: error"
    end

    local urgent = (hr == 0 and min < 30)

    local msg = string.format("Next: %s in %dh %dm", next_prayer, hr, min)
    return colorize(msg, urgent)
end


return {
    fetch_async = fetch_async,
    format_output = format_output
}
