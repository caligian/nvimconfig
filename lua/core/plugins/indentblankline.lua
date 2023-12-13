local indent = require "ibl"
local indentblankline = {}

function indentblankline.set_highlight()
  local normal = highlight "Normal"
  if not normal.guibg then
    return
  end

  if isdark(normal.guibg) then
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
  indentblankline.set_highlight()
  indent.setup(self.config or {})
end

return indentblankline
