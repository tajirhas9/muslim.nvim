-- 2026-03-03 00:00:00 UTC in milliseconds
local MECCA_MARCH_3_2026 = 1772496000000

local function fresh_module()
  package.loaded["muslim.prayer_calc"] = nil
  return require("muslim.prayer_calc")
end

local function mecca_module()
  local M = fresh_module()
  M.setup({
    location   = { lat = 21.4225, lng = 39.8262 },
    utc_offset = 3,
    method     = "MWL",
    asr        = "standard",
  })
  M.utc_time = MECCA_MARCH_3_2026
  return M
end

describe("muslim.prayer_calc", function()

  describe("setup config merging", function()
    local M

    before_each(function()
      M = fresh_module()
      M.setup({
        location   = { lat = 21.4225, lng = 39.8262 },
        utc_offset = 3,
        method     = "MWL",
      })
    end)

    it("stores lat from opts", function()
      assert.are.equal(M.config.location.lat, 21.4225)
    end)

    it("stores method from opts", function()
      assert.are.equal(M.config.method, "MWL")
    end)

    it("applies MWL fajr angle (18)", function()
      assert.are.equal(M.config.fajr, 18)
    end)

    it("applies MWL isha angle (17)", function()
      assert.are.equal(M.config.isha, 17)
    end)
  end)

  describe("get_times return structure", function()
    local M, times

    before_each(function()
      M = mecca_module()
      times = M.get_times()
    end)

    it("returns a table", function()
      assert.is_table(times)
    end)

    local keys = { "fajr", "sunrise", "dhuhr", "asr", "sunset", "maghrib", "isha", "midnight" }
    for _, k in ipairs(keys) do
      it("has key: " .. k, function()
        assert.is_not_nil(times[k])
      end)

      it(k .. " is a number", function()
        assert.are.equal(type(times[k]), "number")
      end)
    end
  end)

  describe("time ordering for Mecca (MWL method)", function()
    local M, t

    before_each(function()
      M = mecca_module()
      t = M.get_times()
    end)

    it("fajr < sunrise", function()
      assert.is_true(t.fajr < t.sunrise)
    end)

    it("sunrise < dhuhr", function()
      assert.is_true(t.sunrise < t.dhuhr)
    end)

    it("dhuhr < asr", function()
      assert.is_true(t.dhuhr < t.asr)
    end)

    it("asr < sunset", function()
      assert.is_true(t.asr < t.sunset)
    end)

    it("sunset <= maghrib", function()
      assert.is_true(t.sunset <= t.maghrib)
    end)

    it("maghrib < isha", function()
      assert.is_true(t.maghrib < t.isha)
    end)

    it("isha < midnight", function()
      assert.is_true(t.isha < t.midnight)
    end)
  end)

  describe("different methods produce different fajr times", function()
    it("Singapore fajr (20°) is earlier than MWL fajr (18°)", function()
      local M_mwl = fresh_module()
      M_mwl.setup({ location = { lat = 21.4225, lng = 39.8262 }, utc_offset = 3, method = "MWL" })
      M_mwl.utc_time = MECCA_MARCH_3_2026
      local fajr_mwl = M_mwl.get_times().fajr

      local M_sin = fresh_module()
      M_sin.setup({ location = { lat = 21.4225, lng = 39.8262 }, utc_offset = 3, method = "Singapore" })
      M_sin.utc_time = MECCA_MARCH_3_2026
      local fajr_sin = M_sin.get_times().fajr

      assert.is_true(fajr_sin < fajr_mwl)
    end)
  end)

  describe("Hanafi vs standard Asr", function()
    it("Hanafi asr is later than standard asr", function()
      local M_std = fresh_module()
      M_std.setup({ location = { lat = 21.4225, lng = 39.8262 }, utc_offset = 3, method = "MWL", asr = "standard" })
      M_std.utc_time = MECCA_MARCH_3_2026
      local asr_std = M_std.get_times().asr

      local M_han = fresh_module()
      M_han.setup({ location = { lat = 21.4225, lng = 39.8262 }, utc_offset = 3, method = "MWL", asr = "hanafi" })
      M_han.utc_time = MECCA_MARCH_3_2026
      local asr_han = M_han.get_times().asr

      assert.is_true(asr_han > asr_std)
    end)
  end)

  describe("high latitude adjustment", function()
    it("high_lats='none' returns valid table", function()
      local M = fresh_module()
      M.setup({ location = { lat = 51.5, lng = -0.12 }, utc_offset = 0, method = "MWL", high_lats = "none" })
      M.utc_time = MECCA_MARCH_3_2026
      local t = M.get_times()
      assert.is_table(t)
      assert.is_not_nil(t.fajr)
    end)

    it("high_lats='night_middle' returns valid table", function()
      local M = fresh_module()
      M.setup({ location = { lat = 51.5, lng = -0.12 }, utc_offset = 0, method = "MWL", high_lats = "night_middle" })
      M.utc_time = MECCA_MARCH_3_2026
      local t = M.get_times()
      assert.is_table(t)
      assert.is_not_nil(t.fajr)
    end)
  end)

  describe("get_current_waqt structure", function()
    local M, info

    before_each(function()
      M = mecca_module()
      info = M.get_current_waqt()
    end)

    it("returns a table", function()
      assert.is_table(info)
    end)

    it("has next_waqt_start as a number", function()
      assert.are.equal(type(info.next_waqt_start), "number")
    end)

    it("has next_waqt_name as a string", function()
      assert.are.equal(type(info.next_waqt_name), "string")
    end)

    local valid_waqts = { fajr = true, dhuhr = true, asr = true, maghrib = true, isha = true }
    it("next_waqt_name is a valid waqt", function()
      assert.is_true(valid_waqts[info.next_waqt_name] == true)
    end)

    it("time_left is positive when waqt_name is present", function()
      if info.waqt_name then
        assert.is_true(info.time_left > 0)
      else
        assert.is_true(true) -- between prayers, no time_left required
      end
    end)
  end)

end)
