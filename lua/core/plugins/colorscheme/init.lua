require "core.plugins.colorscheme.manager"

user.plugins.colorscheme = {
  colorscheme = user.colorscheme,
  config = {},
}

local color = user.colorscheme
color.loadall()
color.setdefault()

K.bind({ noremap = true, leader = true }, {
  "htl",
  color.setlight,
  "Set light colorscheme",
}, {
  "htd",
  color.setdark,
  "Set dark colorscheme",
})
