Autocmd("QuitPre", {
  pattern = "*",
  callback = function()
    require("core.REPL").stopall()
  end,
  name = "stop_repls_at_exit",
})
