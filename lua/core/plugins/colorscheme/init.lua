require "core.plugins.colorscheme.colorscheme"

user.plugins.colorscheme = {
  colorscheme = user.colorscheme,
  config = {},
}

Colorscheme.loadall()
Colorscheme.setdefault()

K.bind({ noremap = true, leader = true }, {
  "htt",
  function()
    local themes = table.keys(Colorscheme.colorscheme)
    local current = vim.g.colors_name or "<unknown>"
    local prompt = sprintf('Select colorscheme (current: %s) > ', current)

    vim.ui.select(themes, {
      prompt = prompt
    }, function (choice)
      if choice then
        Colorscheme.set(choice)
      end
    end)
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
