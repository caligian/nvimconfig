local indentblankline = {
  config = {
    indent = {char = '>' },
    scope = {enabled = true, char = '>'},
    whitespace = {
      remove_blankline_trail = false,
      highlight = {'IblWhitespace', 'Function', 'Label'},
    }
  },
}

function indentblankline.set_highlight()
  local normal = highlight "Normal"

  if not normal.guibg then
    return
  end

  local cursor = highlight "Cursor" or {}
  local cursorbg = cursor.guibg or "#000000"
  local bg = normal.guibg
  local scope
  local fg

  if is_dark(bg) then
    fg = lighten(bg, 15)
    scope = lighten(bg, 25)
  else
    fg = darken(bg, 15)
    scope = darken(bg, 25)
  end

  highlightset("IblIndent", { guifg = fg })
  highlightset("IblWhitespace", { guifg = cursorbg })
  highlightset("IblScope", { guifg = scope })
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
