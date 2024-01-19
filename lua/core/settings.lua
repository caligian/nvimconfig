--- @type string
user.colorscheme = "darksolar"

--- @type ({ft: string}|string|{pattern: string|string[]}|string[])[]
user.temp_buffer_patterns = {
  { ft = "spectre_panel" },
  { ft = "qf" },
  "__*",
  "/usr/share/nvim/runtime/doc*",
  { ft = "help" },
  "*.log",
  { ft = "startuptime" },
}

--- @enum
user.exclude_recent_buffer_filetypes = {
  TelescopePrompt = true,
  netrw = true,
  [""] = true,
  tagbar = true,
}

--- @enum
user.enable = {
  buffer_history = true,
  temp_buffers = true,
  mappings = true,
  autocmds = true,
  commands = true,
  bookmarks = true,
  buffergroups = true,
  filetypes = true,
  repl = true,
  plugins = true,
}

--- TODO
-- revamp defaults
-- move applying defaults to user_utils.lua
-- provide options to toggle bookmarks, buffergroups
-- same for repl

if req2path "user.settings" then
  requirex "user.settings"
end
