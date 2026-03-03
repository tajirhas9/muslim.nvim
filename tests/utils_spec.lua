local M = require("muslim.utils")

local HOUR   = 3600000
local MINUTE = 60000

describe("muslim.utils", function()

  describe("is_date_table", function()
    it("returns true for valid date table", function()
      assert.is_true(M.is_date_table({ year = 2026, month = 3, day = 3 }))
    end)

    it("returns false for empty table", function()
      assert.is_false(M.is_date_table({}))
    end)

    it("returns false for a string", function()
      assert.is_false(M.is_date_table("string"))
    end)

    it("returns false for nil", function()
      assert.is_false(M.is_date_table(nil))
    end)

    it("returns false when day is missing", function()
      assert.is_false(M.is_date_table({ year = 2026, month = 3 }))
    end)
  end)

  describe("value", function()
    it("extracts number from '90 min'", function()
      assert.are.equal(M.value("90 min"), 90)
    end)

    it("extracts number from '1 min'", function()
      assert.are.equal(M.value("1 min"), 1)
    end)

    it("extracts 0 from '0'", function()
      assert.are.equal(M.value("0"), 0)
    end)

    it("returns 0 for nil", function()
      assert.are.equal(M.value(nil), 0)
    end)

    it("returns 0 for non-numeric string", function()
      assert.are.equal(M.value("abc"), 0)
    end)

    it("extracts negative number '-5'", function()
      assert.are.equal(M.value("-5"), -5)
    end)

    it("extracts decimal '4.5'", function()
      assert.are.equal(M.value("4.5"), 4.5)
    end)
  end)

  describe("is_min", function()
    it("returns true for '1 min'", function()
      assert.is_true(M.is_min("1 min"))
    end)

    it("returns true for '90 min'", function()
      assert.is_true(M.is_min("90 min"))
    end)

    it("returns false for '90' (no min suffix)", function()
      assert.is_false(M.is_min("90"))
    end)

    it("returns false for nil", function()
      assert.is_false(M.is_min(nil))
    end)

    it("returns false for empty string", function()
      assert.is_false(M.is_min(""))
    end)
  end)

  describe("format_time", function()
    it("formats epoch 0 as 00:00 in 24h", function()
      assert.are.equal(M.format_time(0, 0, "24h"), "00:00")
    end)

    it("formats 1 hour as 01:00 in 24h", function()
      assert.are.equal(M.format_time(HOUR, 0, "24h"), "01:00")
    end)

    it("formats 14 hours as 14:00 in 24h", function()
      assert.are.equal(M.format_time(14 * HOUR, 0, "24h"), "14:00")
    end)

    it("applies 60-minute utc_offset", function()
      assert.are.equal(M.format_time(HOUR, 60, "24h"), "02:00")
    end)

    it("formats 14:00 as 02:00 PM in 12H", function()
      assert.are.equal(M.format_time(14 * HOUR, 0, "12H"), "02:00 PM")
    end)

    it("formats 01:00 as 01:00 AM in 12H", function()
      assert.are.equal(M.format_time(HOUR, 0, "12H"), "01:00 AM")
    end)

    it("formats noon (12:00) as 12:00 PM in 12H", function()
      assert.are.equal(M.format_time(12 * HOUR, 0, "12H"), "12:00 PM")
    end)

    it("formats 14:00 as 2:00 PM in 12h (no leading zero)", function()
      assert.are.equal(M.format_time(14 * HOUR, 0, "12h"), "2:00 PM")
    end)

    it("returns '-----' for nil timestamp", function()
      assert.are.equal(M.format_time(nil, 0, "24h"), "-----")
    end)

    it("returns '-----' for NaN timestamp", function()
      assert.are.equal(M.format_time(0 / 0, 0, "24h"), "-----")
    end)
  end)

  describe("to_fixed", function()
    it("pads single digit to two characters", function()
      assert.are.equal(M.to_fixed(1, 0), "01")
    end)

    it("does not pad two-digit numbers", function()
      assert.are.equal(M.to_fixed(10, 0), "10")
    end)

    it("formats decimal with one place", function()
      assert.are.equal(M.to_fixed(1.5, 1), "1.5")
    end)
  end)

  describe("format", function()
    local waqt_during = {
      waqt_name      = "fajr",
      time_left      = HOUR,
      next_waqt_name = "dhuhr",
      next_waqt_start = 0,
    }

    it("shows current waqt end and next waqt time when countdown_only=false", function()
      local result = M.format(waqt_during, 0, "24h", false)
      assert.is_truthy(result:find("Fajr ends in"))
      assert.is_truthy(result:find("Dhuhr at:"))
    end)

    it("shows countdown-only format when countdown_only=true", function()
      local result = M.format(waqt_during, 0, "24h", true)
      assert.is_truthy(result:find("Dhuhr in"))
      assert.is_truthy(result:find("h"))
      assert.is_truthy(result:find("m"))
    end)

    it("shows next waqt time when between prayers (no cur_waqt)", function()
      local waqt_between = {
        next_waqt_name  = "fajr",
        next_waqt_start = 0,
      }
      local result = M.format(waqt_between, 0, "24h", false)
      assert.is_truthy(result:find("^Fajr at:"))
    end)
  end)

  describe("get_warning_level", function()
    it("returns green when time_left >= 1 hour", function()
      local result = M.get_warning_level({ time_left = 2 * HOUR })
      assert.are.equal(result.fg, "#008000")
    end)

    it("returns orange when time_left is 45 minutes", function()
      local result = M.get_warning_level({ time_left = 45 * MINUTE })
      assert.are.equal(result.fg, "#ffa500")
    end)

    it("returns red when time_left is 20 minutes", function()
      local result = M.get_warning_level({ time_left = 20 * MINUTE })
      assert.are.equal(result.fg, "#ff2c2c")
    end)

    it("returns orange when time_left is just under 1 hour", function()
      local result = M.get_warning_level({ time_left = 59 * MINUTE + 59000 })
      assert.are.equal(result.fg, "#ffa500")
    end)

    it("returns orange when time_left is exactly 30 minutes (boundary)", function()
      local result = M.get_warning_level({ time_left = 30 * MINUTE })
      assert.are.equal(result.fg, "#ffa500")
    end)
  end)

end)
