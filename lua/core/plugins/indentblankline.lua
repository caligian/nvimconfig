local indent = require("ibl")
local indentblankline = plugin.get("indentblankline")
indentblankline.methods = {}

function indentblankline.methods.set_highlight()
	local normal = highlight("Normal")
	normal.guibg = normal.guibg or "#000000"

	if islight(normal.guibg) then
		normal.guifg = darken(normal.guibg, 20)
	else
		normal.guifg = lighten(normal.guibg, 20)
	end

	highlightset("IblIndent", { guifg = normal.guifg })
end

indentblankline.autocmds = {
	set_indentchar_color = {
		"ColorScheme",
		{ pattern = "*", callback = indentblankline.methods.set_highlight },
	},
}

function indentblankline:setup()
	indentblankline.methods.set_highlight()
	indent.setup(self.config or {})
end

return indentblankline
