local data_dir = vim.fn.stdpath "data"

user.colorscheme = "earlysummer"

user.dir = vim.fn.stdpath "config"

user.user_dir = path.join(os.getenv "HOME", ".nvim")

user.data_dir = data_dir

user.plugins_dir = path.join(data_dir, "lazy")

user.temp_buffer_patterns = {
  qflist = { ft = "qf" },
  temp_buffers = "^__",
  vim_help = "/usr/share/nvim/runtime/doc",
  help_files = { ft = "help" },
  log_files = "%.log$",
  startuptime = { ft = "startuptime" },
}

user.exclude_recent_buffer_filetypes = { TelescopePrompt = true, netrw = true, [""] = true, tagbar = true }


if req2path "user.globals" then
  requirex "user.globals"
end
