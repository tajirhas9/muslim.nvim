local utils = require('muslim.utils')
local maths = require('muslim.math')

local M = {
    methods = {
        MWL       = { fajr = 18, isha = 17 },
        ISNA      = { fajr = 15, isha = 15 },
        Egypt     = { fajr = 19.5, isha = 17.5 },
        Makkah    = { fajr = 18.5, isha = "90 min" },
        Karachi   = { fajr = 18, isha = 18 },
        Tehran    = { fajr = 17.7, maghrib = 4.5, midnight = "Jafari" },
        Jafari    = { fajr = 16, maghrib = 4, midnight = "Jafari" },
        France    = { fajr = 12, isha = 12 },
        Russia    = { fajr = 16, isha = 15 },
        Singapore = { fajr = 20, isha = 18 },
        defaults  = { isha = 14, maghrib = "1 min", midnight = "Standard" }
    },
    config = {
        dhuhr = "0 min",
        asr = "standard",
        high_lats = "night_middle",
        offset = {},
        format = "24h",
        rounding = "nearest",
        utc_offset = 0,                  -- minutes or 'auto'
        dst = 0,
        location = { lat = 0, lng = 0 }, -- best effort fallback
        iterations = 1,
        method = 'MWL'
    },
    shadow_factor = {
        standard = 1,
        hanafi = 2
    },
    labels = { "Fajr", "Sunrise", "Dhuhr", "Asr", "Sunset", "Maghrib", "Isha", "Midnight" },
    roundings = {
        up = 'ceil',
        down = 'floor',
        nearest = 'round'
    },
    adjusted = false
}


local update_method = function()
    local method_adjustments = M.methods[M.config.method]
    local default = M.methods.defaults
    for k, v in pairs(method_adjustments) do M.config[k] = v end

    for k, v in pairs(default) do
        if M.config[k] == nil then
            M.config[k] = utils.is_min(v) and utils.value(v) or v
        end
    end
end

local sun_position = function(time)
    -- print(string.format('ts: %s\ntime: %s',ts, utils.value(time)))

    local lng = M.config.location.lng
    local D = M.utc_time / 86400000 - 10957.5 + utils.value(time) / 24 - lng / 360


    local g = maths.mod(357.529 + 0.98560028 * D, 360)
    local q = maths.mod(280.459 + 0.98564736 * D, 360)
    local L = maths.mod(q + 1.915 * maths.sin(g) + 0.020 * maths.sin(2 * g), 360)
    local e = 23.439 - 0.00000036 * D

    local RA = maths.mod(maths.arctan2(maths.cos(e) * maths.sin(L), maths.cos(L)) / 15, 24)

    return {
        declination = maths.arcsin(maths.sin(e) * maths.sin(L)),
        equation = q / 15 - RA
    }
end

local mid_day = function(time)
    local EqT = sun_position(time).equation
    local noon = maths.mod(12 - EqT, 24)
    return noon
end

local asr_angle = function(school, time)
    local shadow_factor = M.shadow_factor[school]
    local lat = M.config.location.lat
    local decl = sun_position(time).declination
    return -maths.arccot(shadow_factor + maths.tan(math.abs(lat - decl)))
end

local angle_time = function(angle, time, direction)
    direction = direction or 1
    local lat = M.config.location.lat
    local decl = sun_position(time).declination
    local numerator = -maths.sin(angle) - maths.sin(lat) * maths.sin(decl)
    local diff = maths.arccos(numerator / (maths.cos(lat) * maths.cos(decl))) / 15
    return mid_day(time) + diff * direction
end

local adjust_time = function(time, base, angle, night, direction)
    direction = direction or 1

    local factors = {
        night_middle = 1 / 2,
        one_seventh = 1 / 7,
        angle_based = 1 / 60 * utils.value(angle)
    }
    local portion = factors[M.config.high_lats] * night
    local time_diff = (time - base) * direction

    if (type(time) ~= "number") or (time_diff > portion) then
        time = base + portion * direction
        M.adjusted = true
    end
    return time
end

local process_time = function(times)
    local horizon = 0.833

    local fajr = angle_time(M.config.fajr, times.fajr, -1)
    local sunrise = angle_time(horizon, times.sunrise, -1)
    local dhuhr = mid_day(times.dhuhr)
    local asr = angle_time(asr_angle(M.config.asr, times.asr), times.asr)
    local sunset = angle_time(horizon, times.sunset)
    local maghrib = angle_time(M.config.maghrib, times.maghrib)

    local isha = angle_time(M.config.isha, times.isha)
    local midnight = mid_day(times.midnight) + 12

    return {
        fajr = fajr,
        sunrise = sunrise,
        dhuhr = dhuhr,
        asr = asr,
        sunset = sunset,
        maghrib = maghrib,
        isha = isha,
        midnight = midnight
    }
end

local adjust_high_lats = function(times)
    if M.config.high_lats == 'none' then
        return times
    end

    M.adjusted = false
    local night = 24 + times.sunrise - times.sunset

    return {
        fajr = adjust_time(times.fajr, times.sunrise, M.config.fajr, night, -1),
        sunrise = times.sunrise,
        dhuhr = times.dhuhr,
        asr = times.asr,
        sunset = times.sunset,
        maghrib = adjust_time(times.maghrib, times.sunset, M.config.maghrib, night),
        isha = adjust_time(times.isha, times.sunset, M.config.isha, night),
        midnight = times.midnight
    }
end

local update_times = function(times)
    if utils.is_min(M.config.maghrib) then
        times.maghrib = times.sunset + utils.value(M.config.maghrib) / 60
    end

    if utils.is_min(M.config.isha) then
        times.isha = times.maghrib + utils.value(M.config.isha) / 60
    end

    if M.config.midnight == 'Jafari' then
        local next_fajr = angle_time(M.config.fajr, 29, -1) / 24
        times.midnight = (times.sunset + (M.adjusted and times.fajr + 24 or next_fajr)) / 2
    end
    times.dhuhr = times.dhuhr + utils.value(M.config.dhuhr) / 60
    return times
end

local adjust_time_offsets = function(times)
    local mins = M.config.offset or {}

    for k, v in pairs(times) do
        if mins[k] then
            times[k] = v + (mins[k] / 60)
        end
    end
    return times
end

local round_time = function(timestamp)
    local rounding = M.roundings[M.config.rounding]

    if not rounding then return timestamp end

    local one_minute = 60000

    if rounding == 'ceil' then
        return math.ceil(timestamp / one_minute) * one_minute
    elseif rounding == 'floor' then
        return math.floor(timestamp / one_minute) * one_minute
    else
        local x = timestamp / one_minute
        local rx = (x >= 0) and math.floor(x + 0.5) or math.ceil(x - 0.5)
        return rx * one_minute
    end
end

local convert_times = function(times)
    local lng = M.config.location.lng

    for k, v in pairs(times) do
        local time = v - lng / 15
        local ts = M.utc_time + math.floor(time * 3600000)
        times[k] = round_time(ts)
    end
    return times
end

local compute_times = function()
    local times = {
        fajr = 5,
        sunrise = 6,
        dhuhr = 12,
        asr = 13,
        sunset = 18,
        maghrib = 18,
        isha = 18,
        midnight = 24
    }

    for _ = 1, M.config.iterations do
        times = process_time(times)
    end
    times = adjust_high_lats(times)
    times = update_times(times)
    times = adjust_time_offsets(times)
    times = convert_times(times)
    return times
end

local format_times = function(times)
    for k, v in pairs(times) do
        times[k] = utils.format_time(v, M.config.utc_offset * 60)
    end
    return times
end

local times = function()
    local times = compute_times()
    -- times = format_times(times)
    return times
end

M.setup = function(opts)
    opts = opts or {}
    for k, v in pairs(opts) do M.config[k] = v end

    update_method()
    M.utc_time = os.time({
            year = os.date('!*t').year,
            month = os.date('!*t').month,
            day = os.date('!*t').day,
            hour = M
                .config.utc_offset,
            min = 0,
            sec = 0
        }) *
        1000
end

M.get_times = function(date)
    if utils.is_date_table(date) == false then
        date = os.date('*t')
    end
    return times()
end

M.get_current_waqt = function()
    local ONE_SECOND = 1 * 1000
    local ONE_DAY = 24 * 60 * 60 * ONE_SECOND
    local waqt_order = { 'fajr', 'dhuhr', 'asr', 'maghrib', 'isha' }
    local waqt_times = M.get_times()
    local cur_time = os.time() * 1000
    local cur_waqt_info = {}

    -- P(waqt_times)

    for i in ipairs(waqt_order) do
        local j = i + 1
        if (j > 5) then j = 1 end
        local waqt_start = waqt_times[waqt_order[i]]
        local next_waqt = waqt_times[waqt_order[j]]

        if (i == 1) then
            next_waqt = waqt_times['sunrise']
        end
        if (i == 5) then
            next_waqt = next_waqt + ONE_DAY
        end
        next_waqt = next_waqt - ONE_SECOND

        -- print(cur_time, waqt_start, next_waqt)
        -- print(string.format('current waqt: %s, next waqt: %s', waqt_order[i], waqt_order[j]))
        if cur_time >= waqt_start and cur_time <= next_waqt then
            -- print(string.format('current waqt: %s, next waqt: %s', waqt_order[i], waqt_order[j]))
            cur_waqt_info = {
                waqt_name = waqt_order[i],
                time_left = next_waqt - cur_time,
                next_waqt_start = next_waqt,
                next_waqt_name = waqt_order[j]
            }
            break
        end
    end
    if next(cur_waqt_info) == nil then
        -- print('current waqt info is empty...')
        for i in ipairs(waqt_order) do
            local next_waqt = waqt_times[waqt_order[i]]
            next_waqt = next_waqt - ONE_SECOND

            if cur_time < next_waqt then
                -- print(string.format('current waqt: %s, next waqt: %s', waqt_order[i], waqt_order[j]))
                cur_waqt_info = {
                    next_waqt_start = next_waqt,
                    next_waqt_name = waqt_order[i]
                }
                break
            end
        end
    end
    return cur_waqt_info
end

-- local p = M
-- p.setup({
--     location = {
--         lat = 22.368122200492397,
--         lng = 91.83082060378923,
--     },
--     utc_offset = 6,
--     asr = 'hanafi',
--     method = 'Karachi'
-- })
--
-- P(p.get_current_waqt())
--
return M
