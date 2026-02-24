local M = {
	config = {
		refresh        = 1,
		latitude       = nil,
		longitude      = nil,
		utc_offset     = 0,
		school         = 'hanafi',
		method         = 'MWL',
		time_format    = '12H', -- '12H' for 12-hour with AM/PM, '24h' for 24-hour
		countdown_only = false,
		-- api_url    = "https://api.aladhan.com/v1/timings"
	},
	prayer_time_text = 'Please wait...',
}



M.setup = function(opts)
	-- Check if plenary is installed
	if not pcall(require, 'plenary') then
		vim.notify('[prayer.nvim] please install plenary.nvim', vim.log.levels.WARN)
		return
	end
	-- Check if lualine is intalled
	if not pcall(require, 'lualine') then
		vim.notify('[prayer.nvim] did not find lualine. only user_commands will be available', vim.log.levels.WARN)
		-- return
	end

	-- init config
	opts = opts or {}
	for k, v in pairs(opts) do M.config[k] = v end

	-- validate config
	if not M.config.latitude or not M.config.longitude or not M.config.utc_offset then
		vim.notify('[prayer.nvim] please set latitude, longitude and utc_offset', vim.log.levels.WARN)
		return
	end

	M.prayer_module = require("muslim.prayer_calc")

	M.prayer_module.setup({
		location = {
			lat = M.config.latitude,
			lng = M.config.longitude,
		},
		utc_offset = M.config.utc_offset,
		asr = M.config.school,
		method = M.config.method
	})

	-- First run
	M.update()

	-- Refresh every x minute(s)
	local timer = vim.loop.new_timer()
	timer:start(
		M.config.refresh * 60 * 1000,
		M.config.refresh * 60 * 1000,
		function()
			M.update()
		end
	)
end

M.update = function()
	local format = require("muslim.utils").format
	M.prayer_time_text = 'Updating prayer times...'

	local current_waqt = M.prayer_module.get_current_waqt()

	M.prayer_time_text = format(current_waqt, M.config.utc_offset, M.config.time_format, M.config.countdown_only)

	-- update lualine if available
	vim.schedule(function()
		M.update_lualine(current_waqt)
	end)
end

M.prayer_time = function()
	return M.prayer_time_text
end

M.today_prayer_time_epochs = function()
	return M.prayer_module.get_times()
end

M.update_lualine = function(current_waqt)
	if not pcall(require, 'lualine') then
		return
	end
	local get_warning_level = require("muslim.utils").get_warning_level
	pcall(function()
		local sections = require("lualine").get_config().sections
		for col, info in pairs(sections) do
			for idx in ipairs(info) do
				local section = info[idx]
				if (section.id == 'muslim.nvim') then
					section.color = get_warning_level(current_waqt)
				end
			end
		end
		require('lualine').setup({
			sections = sections
		})
		require("lualine").refresh {
			place = { "statusline", "tabline", "winbar" }
		}
	end)

	-- Force actual redraw (fixes async updates)
	vim.cmd("redrawstatus!")
end

vim.api.nvim_create_user_command("PrayerTimes", function()
	local waqt_order = { "fajr", "sunrise", "dhuhr", "asr", "sunset", "maghrib", "isha", "midnight" }
	local times = M.prayer_module.get_times()
	local formatted = {}
	for k, v in pairs(times) do
		formatted[k] = require("muslim.utils").format_time(v, M.config.utc_offset * 60, M.config.time_format)
	end
	-- vim.print(formatted)
	print("|" .. string.rep("-", 25) .. "|")
	print(string.format("| %-10s | %-10s |", 'Waqt', 'Time'))
	print("|" .. string.rep("-", 25) .. "|")
	for _, k in ipairs(waqt_order) do
		local v = formatted[k]
		print(string.format("| %-10s | %-10s |", k, v))
	end
	print("|" .. string.rep("-", 25) .. "|")
	return formatted
end, {})

return M
