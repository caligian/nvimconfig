local onedark = {}

local function onedark_theme(theme, config)
	theme = theme or "deep"
	config = config or {}
	local defaults = {
		-- deep, warm, warmer, light, dark, darker
		style = "deep",
		transparent = false,
		term_colors = true,
		ending_tildes = false,
		cmp_itemkind_reverse = false,
		code_style = {
			comments = "italic",
			keywords = "none",
			functions = "italic",
			strings = "none",
			variables = "none",
		},
		lualine = { transparent = false },
		colors = {},
		highlights = {},
		diagnostics = {
			darker = true,
			undercurl = true,
			background = true,
		},
	}

	assert(is_a.t(config))

	table.lmerge(config, defaults)

	config.style = theme

	require("onedark").setup(config)

	vim.cmd("color onedark")
end

table.each({ "deep", "warm", "warmer", "light", "dark", "darker" }, function(t)
	local theme_name = "onedark_" .. t
	onedark[theme_name] = function(config)
		onedark_theme(t, config)
	end
end)

return onedark
