local package_path = vim.split(package.path, ';')

return {
	settings = {
		Lua = {
			path = package_path,
			runtime = {
				version = 'Lua 5.1',
			},
			workspace = {
				library = package_path,
			},
			telemetry = {
				enable = false,
			},
			diagnostics = {
				severity = { { ['undefined-global'] = false } },
				disable = { 'lowercase-global', 'undefined-global' },
			},
		},
	},
}
