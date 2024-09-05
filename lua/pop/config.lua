---@class PluginOptions
---@field from string The email address to send from
local default_config = {
  from = "me@example.com",
}

---@class PluginConfig
---@field parse_opts fun(opts: PluginOptions|nil): PluginOptions
---@field allowed_options table<string, string>
---@field config PluginOptions
---@field get_arguments fun(args: string, config: PluginOptions|nil): string[]
---@field start fun(args: string, config: PluginOptions|nil)
---@field setup fun(opts: PluginOptions|nil)
local M = {
  config = vim.deepcopy(default_config),
}

M.allowed_options = {
  from = "string",
}

local function is_array(...)
  if vim.fn.has("nvim-0.10") == 1 then
    return vim.isarray(...)
  else
    return vim.tbl_islist(...)
  end
end

M.parse_opts = function(opts)
  local options
  if not opts then
    return M.config
  end
  vim.validate({ opts = { opts, "table" } })
  options = vim.tbl_deep_extend("force", M.config, opts or {})
  if M.allowed_options then
    for k, v in pairs(opts) do
      local k_type = M.allowed_options[k]
      if type(k_type) == "table" and not is_array(k_type) then
        vim.validate({ [k] = { v, "table" } })
        for _k, _v in pairs(v) do
          vim.validate({ [_k] = { _v, k_type[_k] } })
        end
      else
        vim.validate({ [k] = { v, k_type } })
      end
    end
  end
  return options
end

local function populate_cmd(cmd, args, tbl, prefix)
  for k, v in pairs(tbl) do
    -- handle margin and padding separately as tables
    if k == "margin" or k == "padding" then
      if type(v) == "table" then
        table.insert(cmd, "--" .. prefix .. k)
        table.insert(cmd, table.concat(v, ","))
      end
    -- table options ('from', 'to', 'subject', 'attach')
    elseif type(v) == "table" and not is_array(v) then
      populate_cmd(cmd, args, v, prefix .. k .. ".")
    -- handle anything that is not the command or language option
    elseif k ~= "command" and k ~= "language" then
      table.insert(cmd, "--" .. prefix .. string.gsub(k, "_", "-"))

      -- if the value is a function, call it with the args, otherwise just use the value
      local value = nil
      if type(v) == "function" then
        value = v(args)
      else
        value = v
      end

      -- Don't append the value if it's a boolean option.
      if type(v) ~= "boolean" then
        table.insert(cmd, value)
      end
    end
  end
end

M.get_arguments = function(args, config)
  local cmd = { "pop" }
  populate_cmd(cmd, args, config)
  return cmd
end

M.start = function(args, config)
  local base_cmd = M.get_arguments(args, config)
  vim.fn.jobstart(base_cmd, {
    on_stdout = function(_, data)
      print(data)
    end,
    on_stderr = function(_, data)
      print(data)
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        vim.notify("[pop.nvim] Email not sent, an error occurred" , vim.log.levels.ERROR, { title = "pop.nvim" })
      else
        vim.notify("[pop.nvim] Email sent correctly" , vim.log.levels.INFO, { title = "pop.nvim" })
      end
    end,
  })
end

M.setup = function(opts)
  local config = M.parse_opts(opts)
  M.config = config
end

return setmetatable(M, {
  __index = function(_, key)
    if key == "setup" then
      return M.setup
    end
    return rawget(M.config, key)
  end,
})
