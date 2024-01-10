local indentblankline = {}

function indentblankline.set_highlight()
  local normal = highlight "Normal"
  if not normal.guibg then
    return
  end

  if is_dark(normal.guibg) then
    normal.guifg = darken(normal.guibg, 20)
  else
    normal.guifg = lighten(normal.guibg, 20)
  end

  highlightset("IblIndent", { guifg = normal.guifg })
end

indentblankline.autocmds = {
  set_indentchar_color = {
    "ColorScheme",
    {
      pattern = "*",
      callback = indentblankline.set_highlight,
    },
  },
}

function indentblankline:setup()
  local indent = require "ibl"
  indentblankline.set_highlight()
  indent.setup(self.config or {})
end

Autocmd("Colorscheme", {
  pattern = "*",
  callback = function()
    indentblankline:setup()
  end,
})

return indentblankline
