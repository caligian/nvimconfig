Lang("tex", {
	server = "texlab",
	bo = {
		textwidth = 80,
		shiftwidth = 4,
		tabstop = 4,
	},
	formatters = {
		{ exe = "latexindent.pl", args = { "-m", "-" }, stdin = true },
	},
})
