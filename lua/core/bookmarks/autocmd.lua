Autocmd("QuitPre", {
  callback = function()
    require("core.Bookmark").save()
  end,
  pattern = "*",
})
