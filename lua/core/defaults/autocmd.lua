Autocmd("TextYankPost", {
	callback = V.partial(vim.highlight.on_yank, { timeout = 100 }),
	pattern = "*",
})
