Autocmd("QuitPre", {
	callback = function()
		Bookmarks.save()
	end,
	pattern = "*",
})
