Autocmd("QuitPre", {
  callback = function() require('core.utils.Bookmark').save() end,
  pattern = "*",
})
