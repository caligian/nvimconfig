require "core.plugins.colorscheme.manager"

user.plugins.colorscheme = {
  colorscheme = user.colorscheme,
  config = {},
}

Autocmd("Colorscheme", {
  name = "change_linenr_bg",
  pattern = "*",
  callback = function()
    local normal = utils.highlight "Normal"
    utils.highlightset("LineNr", { guibg = normal.guibg })
  end,
})

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
