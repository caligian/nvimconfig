local sh = filetype.new "sh"

sh.repl = "/bin/bash"
sh.compile = "/bin/bash"
sh.server = "bashls"
sh.linters = "shellcheck"
sh.formatter = { "shfmt -i 2", stdin = true }
