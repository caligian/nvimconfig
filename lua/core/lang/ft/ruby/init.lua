return {
	commands = {
		build = false,
		compile = "ruby",
		repl = "irb --inf-ruby-mode",
		test = "rspec",
	},
	server = {
		name = "solargraph",
		config = {},
	},
	linters = { "rubocop" },
}
