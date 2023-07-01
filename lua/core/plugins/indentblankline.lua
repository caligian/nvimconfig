local indent = require "indent_blankline"
local indentblankline = plugin.get 'indentblankline'

function indentblankline.set_highlight()
  local normal = utils.highlight "Normal"
  normal.guibg = normal.guibg or '#000000'

  if utils.islight(normal.guibg) then
    normal.guifg = utils.darken(normal.guibg, 20)
  else
    normal.guifg = utils.lighten(normal.guibg, 20)
  end

  utils.hi("IndentBlankLineChar", { guifg = normal.guifg, })
end

indentblankline.autocmds = {
  indentblankline = {
    set_indentchar_color = {
      "ColorScheme",
      { pattern = "*", callback = indentblankline.set_highlight },
    },
  }
}

function indentblankline:setup()
  indentblankline.set_highlight()
  indent.setup(self.config or {})
end
