local data_dir = vim.fn.stdpath "data"

table.merge(user, {
  lsp = user.lsp or {},
  dir = vim.fn.stdpath "config",
  user_dir = path.join(os.getenv "HOME", ".nvim"),
  data_dir = data_dir,
  plugins_dir = path.join(data_dir, "lazy"),
  plugins = user.plugins or {},
  shell = "/usr/bin/zsh",
  font = "Liberation Mono:h13",
  colorscheme = {
    dark = "neobones",
    light = "vimbones",
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
  bitmap_font = "Terminus:h11",
})

utils.set_font(user.font, 13)

req "user.globals"
