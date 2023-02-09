return {
	commands = {
		build = false,
		compile = 'lua5.1',
		repl = 'lua5.1',
		test = false,
	},
	server = {
		name = 'sumneko_lua',
		config = require('core.lang.ft.lua.sumneko_lua'),
	},
	linters = { 'luacheck' },
	formatters = {
		{
			exe = 'stylua',
			args = {
				'--line-endings Unix',
				'--column-width 1000',
				'--quote-style AutoPreferSingle',
				'--collapse-simple-statement Always',
				'-',
			},
			stdin = true,
		},
	},
}
