filetype.python = {
  compile = "python",
  test = "pytest",
  repl = "python -q",
  server = "jedi_language_server",
  linters = "pylint",
  formatters = { { exe = "black", args = { "-q", "-" }, stdin = true } },
  bo = { shiftwidth = 4, tabstop = 4 },
}
