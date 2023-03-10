return {
	compile = "lua5.1",
	repl = "lua5.1",
	linters = "luacheck",

	server = {
		name = "lua_ls",
		config = require("core.lang.ft.lua.sumneko_lua"),
	},

	formatters = {
		{
			exe = "stylua",
			args = {
				"--call-parentheses None",
				"--collapse-simple-statement Never",
				"--line-endings Unix",
				"--column-width 100",
				"--quote-style AutoPreferDouble",
				"--indent-type Spaces",
				"--indent-width 2",
				"-",
			},
			stdin = true,
		},
	},

	bo = {
		shiftwidth = 2,
		tabstop = 2,
	},
}
