return {
	-- For builtin repl, build-compile-test-debug utils
	commands = {
		build = false,
		compile = "python",
		test = "pytest",
		repl = "python -q",
		debug = false,
	},

	-- And this is for nvim-lspconfig
	server = {
		name = "pyright",
		config = {},
	},

	-- nvim-lint will use this
	linters = { "pylint" },

	-- formatter.nvim will use this
	-- Current buffer path will be append at the end
	-- If a string is passed, it will considered as formatter.nvim's builtin
	formatters = {
		{ exe = "black", args = { "-q", "-" }, stdin = true },
	},
}
