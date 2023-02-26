user.lsp = user.lsp or {}
user.plugins = user.plugins or {}
user.shell = "/usr/bin/zsh"
user.font = "Hack Nerd Font:h13"
user.colorscheme = "terafox"
user.conjure_langs = {
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
}

V.require("user.globals")
