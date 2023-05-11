local indent = req "indent_blankline"

local function set_highlight()
  local normal = utils.highlight "Normal"
  normal.guifg = utils.lighten(normal.guibg or "#000000", 30)
  utils.highlightset("IndentBlankLineChar", {
    guifg = normal.guifg,
  })
end

plugin.indentblankline = {
  methods = {
    set_highlight = set_highlight,
  },

  autocmds = {
    set_indentblankline_hi = {
      "Colorscheme",
      { pattern = "*", callback = set_highlight },
    },
  },

  setup = function(self)
    set_highlight()
    indent.setup(self.config)
  end,
}
