local cfg = require("pop.config")

---@class Plugin
---@field setup fun(opts: PluginOptions|nil)
local M = {}

M.setup = function(opts)
  cfg.setup(opts or {})
  vim.api.nvim_create_user_command("Pop", function(args)
    cfg.start(args, cfg.config)
  end, {
    desc = "Send an email using pop by [charm](https://charm.sh/)",
    force = true,
    range = true,
  })
end

return M
