local tex = {}

tex.server = "texlab"

tex.bo = {
  textwidth = 80,
  shiftwidth = 4,
  tabstop = 4,
}

tex.formatter = {
  buffer = "latexindent.pl -m -",
  stdin = true,
}

return tex
