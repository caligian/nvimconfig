local data_dir = vim.fn.stdpath "data"

dict.merge(user, {
  colorscheme = 'base16-irblack',
  lsp = user.lsp or {},
  dir = vim.fn.stdpath "config",
  user_dir = path.join(os.getenv "HOME", ".nvim"),
  data_dir = data_dir,
  plugins_dir = path.join(data_dir, "lazy"),
  plugins = user.plugins or {},
  shell = "/bin/bash",
  fonts = { {"Liberation Mono", h=14}, {"Noto Mono", h=14} },
  temp_buffer_patterns = {
    qflist = { ft = "qf" },
    temp_buffers = "^__",
    vim_help = "/usr/share/nvim/runtime/doc",
    help_files = { ft = "help" },
    log_files = '%.log$'
  },
})

user.userdir = user.user_dir
user.datadir = user.data_dir
user.pluginsdir = user.plugins

req "user.globals"
