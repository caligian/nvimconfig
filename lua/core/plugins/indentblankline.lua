local indent = require "indent_blankline"

local function set_highlight()
  local normal = utils.highlight "Normal"
  normal.guibg = normal.guibg or '#000000'

  if utils.islight(normal.guibg) then
    normal.guifg = utils.darken(normal.guibg, 20)
  else
    normal.guifg = utils.lighten(normal.guibg, 20)
  end

  utils.hi("IndentBlankLineChar", { guifg = normal.guifg, })
end

plugin.indentblankline = {
  methods = {
    set_highlight = set_highlight,
  },

  autocmds = {
    set_indentchar_color = {
      "ColorScheme",
      { pattern = "*", callback = set_highlight },
    },
  },

  on_attach = function(self)
    set_highlight()
    indent.setup(self.config)
  end,
}
