local indent = require "indent_blankline"
local indentblankline = plugin.get "indentblankline"

function indentblankline.set_highlight()
    local normal = highlight "Normal"
    normal.guibg = normal.guibg or "#000000"

    if is_light(normal.guibg) then
        normal.guifg = darken(normal.guibg, 20)
    else
        normal.guifg = lighten(normal.guibg, 20)
    end

    hi("IndentBlankLineChar", { guifg = normal.guifg })
end

indentblankline.autocmds = {
    set_indentchar_color = {
        "ColorScheme",
        { pattern = "*", callback = indentblankline.set_highlight },
    },
}

function indentblankline:setup()
    indentblankline.set_highlight()
    indent.setup(self.config or {})
end


