return {
  server = "texlab",
  bo = {
    textwidth = 80,
    shiftwidth = 2,
    tabstop = 2,
  },
  formatters = {
    { exe = "latexindent.pl", args = { "-m", "-" }, stdin = true },
  },
}
