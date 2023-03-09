Autocmd("QuitPre", {
	pattern = "*",
	callback = REPL.stopall,
	name = "repl_stopall_at_quit",
})
