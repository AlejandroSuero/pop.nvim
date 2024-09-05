describe("[pop.nvim tests]", function()
  describe("setup", function()
    it("should set up the plugin with the default config", function()
      require("pop").setup()
      local expected = require("pop.config").config

      assert.not_nil(expected)
      assert.are.same(expected.from, "me@example.com")
    end)

    it("should set up the plugin with a custom config", function()
      require("pop").setup({
        from = "me2@example.com",
      })
      local expected = require("pop.config").config

      assert.not_nil(expected)
      assert.are.same(expected.from, "me2@example.com")
    end)
  end)
end)
