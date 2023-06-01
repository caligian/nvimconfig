filetype.sh = {
  repl = user.shell,
  compile = user.shell,
  server = "bashls",
  linters = "shellcheck",
  formatters = { {exe='shfmt', stdin=true, args={'-i 2'} } }
}
