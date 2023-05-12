local data_dir = vim.fn.stdpath "data"

dict.merge(user, {
  lsp = user.lsp or {},

  dir = vim.fn.stdpath "config",

  user_dir = path.join(os.getenv "HOME", ".nvim"),

  data_dir = data_dir,

  plugins_dir = path.join(data_dir, "lazy"),

  plugins = user.plugins or {},

  shell = "/usr/bin/zsh",

  font = { family = "Liberation Mono", height = 13 },

  temp_buffer_patterns = {
    qflist = { ft = "qf" },
    temp_buffers = "^__",
    vim_help = "/usr/share/nvim/runtime/doc",
    help_files = { ft = "help" },
  },

  colorscheme = 'starry',
})

utils.set_font(user.font.family, user.font.height)

req "user.globals"
