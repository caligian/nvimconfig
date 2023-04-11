local indent = req("indent_blankline")

local function set_highlight()
	local normal = utils.highlight("Normal")
	normal.guifg = utils.lighten(normal.guibg or "#000000", 30)
	utils.highlightset("IndentBlankLineChar", {
		guifg = normal.guifg,
	})
end

Autocmd("Colorscheme", { pattern = "*", callback = set_highlight })

indent.setup({
	show_current_context = false,
	show_current_context_start = false,
})

set_highlight()
