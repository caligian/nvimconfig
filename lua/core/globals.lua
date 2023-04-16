local data_dir = vim.fn.stdpath "data"

table.merge(user, {
  lsp = user.lsp or {},
  dir = vim.fn.stdpath "config",
  user_dir = path.join(os.getenv "HOME", ".nvim"),
  data_dir = data_dir,
  plugins_dir = path.join(data_dir, "lazy"),
  plugins = user.plugins or {},
  shell = "/usr/bin/zsh",
  font = { family = "Liberation Mono", height = 13 },
  bitmap_font = { family = "Terminus", height = 11 },

  temp_buffer_patterns = {
    temp_buffers = "^__temp_buffer",
    vim_help = "/usr/share/nvim/runtime/doc",
    help_files = function(bufnr)
      return vim.api.nvim_buf_get_option(bufnr, "filetype") == "help"
    end,
  },

  colorscheme = {
    dark = "oceanic",
    light = "kanagawa-lotus",
    use = "light",
  },

  conjure_langs = {
    "clojure",
    "fennel",
    "common-lisp",
    "guile",
    "hy",
    "janet",
    "julia",
    "lua",
    "python",
    "racket",
    "rust",
    "scheme",
  },
})

if vim.fn.has "gui" == 1 then
  utils.set_font(user.font.family, user.font.height)
end

req "user.globals"
