require("core.plugins.colorscheme.colorscheme")

user.plugins.colorscheme = {
	colorscheme = user.colorscheme,
	config = {},
}

Colorscheme.loadall()
Colorscheme.setdefault()

K.bind({ noremap = true, leader = true }, {
	"htt",
	function()
		local themes = keys(Colorscheme.colorscheme)
		local current = vim.g.colors_name or "<unknown>"
		local menu = Buffer.menu("Current: " .. current, themes, nil, function(choice)
			Colorscheme.set(choice)
		end)
		menu:split("v", { resize = 0.2, reverse = true, min = 29 })
		Buffer.ids[menu.bufnr] = nil
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
