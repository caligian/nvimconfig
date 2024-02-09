--- @type string
user.colorscheme = "ayu"

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
