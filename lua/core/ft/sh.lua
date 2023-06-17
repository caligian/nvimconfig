filetype.sh = {
  repl = user.shell,
  compile = user.shell,
  server = "bashls",
  linters = "shellcheck",
  formatter = { 'shfmt -i 2', stdin=true }
}
