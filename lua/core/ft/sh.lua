local sh = Filetype "sh"

sh.repl = "/bin/bash"
sh.compile = "/bin/bash"
sh.lsp_server = "bashls"
sh.linters = "shellcheck"
sh.formatter = { "shfmt -i 2", stdin = true }

return sh
