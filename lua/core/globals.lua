user.colorscheme = "material"

user.font = { "Ubuntu Mono", "11" }

user.temp_buffer_patterns = {
  qflist = { ft = "qf" },
  temp_buffers = "^__",
  vim_help = "/usr/share/nvim/runtime/doc",
  help_files = { ft = "help" },
  log_files = "%.log$",
  startuptime = { ft = "startuptime" },
}

user.exclude_recent_buffer_filetypes = {
  TelescopePrompt = true,
  netrw = true,
  [""] = true,
  tagbar = true,
}

if req2path "user.globals" then
  requirex "user.globals"
end
