require("core.plugins.colorscheme.colorscheme")

user.plugins.colorscheme = {
  background = "light",
  colorscheme = user.colorscheme,
  config = {},
}

Colorscheme.loadall()
Colorscheme.setdefault()

K.bind({ noremap = true, leader = true }, {
  "htt",
  function()
    local themes = table.keys(Colorscheme.colorscheme)
    local menu = Buffer.menu("<CR> Apply colorscheme", themes, false, function(choice)
      Colorscheme.set(choice)
    end)
    menu:split("v", { resize = 0.2, reverse = true, min = 29 })
    menu:hook("WinLeave", V.partial(menu.delete, menu))
    Buffer.ids[menu.bufnr] = nil
  end,
  "Choose colorscheme",
}, {
  "htl",
  Colorscheme.setlight,
  "Set light colorscheme",
}, {
  "htd",
  Colorscheme.setdark,
  "Set dark colorscheme",
})
