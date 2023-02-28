return {
  server = "texlab",
  hooks = {
    function()
      vim.bo.textwidth = 80
      vim.bo.spell = true
    end,
  },
  bo = {
    shiftwidth = 2,
    tabstop = 2,
  },
  formatters = {
    { exe = "latexindent.pl", args = { "-m", "-" }, stdin = true },
  },
}
