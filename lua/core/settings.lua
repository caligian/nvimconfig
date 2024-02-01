--- @type string
user.colorscheme = "material-darker"

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
  buffer_groups = true,
  filetypes = true,
  repl = true,
  plugins = true,
}
