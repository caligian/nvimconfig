local data_dir = vim.fn.stdpath "data"

table.merge(user, {
  temp_buffer_patterns = {
    temp_buffers = "^__temp_buffer",
    vim_help = "/usr/share/nvim/runtime/doc",
    startuptime = "startuptime%]$",
    help_files = function(bufnr)
      return vim.api.nvim_buf_get_option(bufnr, "filetype") == "help"
    end,
  },
  lsp = user.lsp or {},
  dir = vim.fn.stdpath "config",
  user_dir = path.join(os.getenv "HOME", ".nvim"),
  data_dir = data_dir,
  plugins_dir = path.join(data_dir, "lazy"),
  plugins = user.plugins or {},
  shell = "/usr/bin/zsh",
  font = { family = "Noto Mono", height = 12 },
  colorscheme = {
    dark = "oceanic",
    light = "OceanicNextLight",
    use = "dark",
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
  bitmap_font = { family = "Terminus", height = 11 },
})

if vim.fn.has "gui" == 1 then
  utils.set_font(user.font.family, user.font.height)
end

req "user.globals"
