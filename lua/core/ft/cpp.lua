local cpp = filetype.get("cpp")

cpp.lsp_server = {
	"ccls",
	init_options = {
		compilationDatabaseDirectory = "build",
		index = {
			threads = 0,
		},
		clang = {
			excludeArgs = { "-frounding-math" },
		},
	},
}

return cpp
