local zsh = filetype.get("zsh")

zsh.repl = "/usr/bin/zsh"
zsh.compile = "/usr/bin/zsh %s"
zsh.linters = "shellcheck"

return zsh
