Autocmd("TextYankPost", {
	pattern = "*",
	callback = function()
		vim.highlight.on_yank({ timeout = 200 })
	end,
})

Autocmd("BufEnter", {
	pattern = "*i3",
	callback = function()
		vim.cmd("set ft=i3config")
		vim.bo.shiftwidth = 2
		vim.bo.tabstop = 2
	end,
})
