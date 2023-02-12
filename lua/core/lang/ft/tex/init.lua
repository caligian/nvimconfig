return {
  server = "texlab",
  bo = {
    shiftwidth = 2,
    tabstop = 2,
  },
  formatters = {
    { exe = "latexindent.pl", args = { "-m", "-" }, stdin = true },
  },
}
