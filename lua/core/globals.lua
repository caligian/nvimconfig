local data_dir = vim.fn.stdpath("data")

table.merge(user, {
  lsp = user.lsp or {},
  dir = vim.fn.stdpath("config"),
  user_dir = path.join(os.getenv("HOME"), ".nvim"),
  data_dir = data_dir,
  plugins_dir = path.join(data_dir, "lazy"),
  plugins = user.plugins or {},
  shell = "/usr/bin/zsh",
  font = "Hack Nerd Font:h13",
  colorscheme = {
    dark = "nordic",
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
})

V.require("user.globals")
