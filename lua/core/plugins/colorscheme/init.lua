user.plugins.colorscheme = {
  colorscheme = user.colorscheme,
  config = {},
}

Colorscheme.loadall()
Colorscheme.setdefault()

K.bind({ noremap = true, leader = true }, {
  "htl",
  Colorscheme.setlight,
  "Set light colorscheme",
}, {
  "htd",
  Colorscheme.setdark,
  "Set dark colorscheme",
})
