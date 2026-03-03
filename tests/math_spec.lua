local M = require("muslim.math")

local function near(a, b, eps)
  return math.abs(a - b) < (eps or 1e-9)
end

describe("muslim.math", function()

  describe("dtr / rtd", function()
    it("converts 180 degrees to pi", function()
      assert.is_true(near(M.dtr(180), math.pi))
    end)

    it("converts pi to 180 degrees", function()
      assert.is_true(near(M.rtd(math.pi), 180))
    end)

    it("round-trips degrees through dtr/rtd", function()
      assert.is_true(near(M.rtd(M.dtr(45)), 45))
    end)
  end)

  describe("sin", function()
    it("sin(0) = 0", function()
      assert.is_true(near(M.sin(0), 0))
    end)

    it("sin(90) = 1", function()
      assert.is_true(near(M.sin(90), 1))
    end)

    it("sin(30) = 0.5", function()
      assert.is_true(near(M.sin(30), 0.5))
    end)
  end)

  describe("cos", function()
    it("cos(0) = 1", function()
      assert.is_true(near(M.cos(0), 1))
    end)

    it("cos(90) ≈ 0", function()
      assert.is_true(near(M.cos(90), 0, 1e-9))
    end)
  end)

  describe("tan", function()
    it("tan(45) = 1", function()
      assert.is_true(near(M.tan(45), 1))
    end)
  end)

  describe("arcsin", function()
    it("arcsin(1) = 90", function()
      assert.is_true(near(M.arcsin(1), 90))
    end)

    it("arcsin(0) = 0", function()
      assert.is_true(near(M.arcsin(0), 0))
    end)
  end)

  describe("arccos", function()
    it("arccos(1) = 0", function()
      assert.is_true(near(M.arccos(1), 0))
    end)

    it("arccos(0) = 90", function()
      assert.is_true(near(M.arccos(0), 90))
    end)
  end)

  describe("arctan2", function()
    it("arctan2(1, 1) = 45", function()
      assert.is_true(near(M.arctan2(1, 1), 45))
    end)
  end)

  describe("arccot", function()
    it("arccot(1) = 45", function()
      assert.is_true(near(M.arccot(1), 45))
    end)
  end)

  describe("mod", function()
    it("wraps negative values", function()
      assert.are.equal(M.mod(-1, 24), 23)
    end)

    it("wraps values over the modulus", function()
      assert.are.equal(M.mod(25, 24), 1)
    end)

    it("zero stays zero", function()
      assert.are.equal(M.mod(0, 360), 0)
    end)

    it("positive passthrough", function()
      assert.are.equal(M.mod(10, 24), 10)
    end)
  end)

  describe("trig identity", function()
    it("sin²(x) + cos²(x) = 1 for arbitrary angle", function()
      local s = M.sin(37)
      local c = M.cos(37)
      assert.is_true(near(s * s + c * c, 1))
    end)
  end)

end)
