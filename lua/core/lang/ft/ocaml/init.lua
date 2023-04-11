Lang("ocaml", {
	repl = {
		"utop",
		on_input = function(s)
			if not s[#s]:match(";;$") then
				return table.append(s, ";;")
			end
			return s
		end,
	},
	server = "ocamllsp",
	formatters = {
		{ exe = "ocamlformat", args = { "-" } },
	},
	bo = { tabstop = 2, shiftwidth = 2 },
})
