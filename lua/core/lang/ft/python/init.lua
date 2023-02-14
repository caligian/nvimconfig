return {
  compile = "python",
  test = "pytest",
  repl = "python -q",
  server = "pyright",
  linters = "pylint",
  formatters = { { exe = "black", args = { "-q", "-" }, stdin = true } },
  bo = { shiftwidth = 4, tabstop = 4 },
}
