local elixir = filetype("elixir")
local function isproject(current_dir)
	local prev_dir = vim.fn.fnamemodify(current_dir, ":h")
	local ls = dir.getallfiles(prev_dir)
	local check = path.join(prev_dir, "mix.exs")

	for i = 1, #ls do
		if string.match(ls[i], check) then
			return true
		end
	end

	return false
end

elixir.repl = {
	{ "iex", workspace = "iex" },
}

elixir.formatter = {
	"mix format - ",
	stdin = true,
}

elixir.compile = {
	"elixir %s",
	workspace = "mix run",
}

elixir.test = {
	workspace = "mix test",
}

elixir.lsp_server = {
	"elixirls",
	cmd = {
		path.join(user.data_dir, "lsp-servers", "elixir-ls", "scripts", "language_server.sh"),
	},
}

elixir.mappings = {
	compile_and_run_buffer = {
		"n",
		"<leader>rc",
		function()
			local bufnr = buffer.bufnr()
			Repl.if_running(bufnr, function(x)
				buffer.save(bufnr)
				Repl.send(x, sprintf('c("%s")', buffer.name()))
			end)
		end,
		{ desc = "compile and run buffer" },
	},
	filetype_compile_and_run_buffer = {
		"n",
		"<localleader>rc",
		function()
			local bufnr = buffer.bufnr()
			Repl.if_running("elixir", function(x)
				buffer.save(bufnr)
				Repl.send(x, sprintf('c("%s")', buffer.name()))
			end)
		end,
		{ desc = "compile and run buffer" },
	},
}

elixir.abbrevs = {
	puts = "IO.inspect",
	dump = "inspect",
	print = "IO.write",
}

return elixir
