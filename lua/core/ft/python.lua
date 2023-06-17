filetype.python = {
  compile = "python3",
  test = "pytest",
  repl = "ipython3",
  server = "pyright",
  linters = "pylint",
  formatter = { 'black -q -', stdin = true },
  bo = { shiftwidth = 4, tabstop = 4 },
}
