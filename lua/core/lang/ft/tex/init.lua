return {
  server = "texlab",
  hooks = {
    function()
      vim.wo.spell = true
    end,
  },
  bo = {
    textwidth = 80,
    shiftwidth = 2,
    tabstop = 2,
  },
  formatters = {
    { exe = "latexindent.pl", args = { "-m", "-" }, stdin = true },
  },
}
