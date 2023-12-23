bookmark.mappings = {
  opts = {
    noremap = true,
  },
  add_buffer = {
    "gba",
    function()
      local count = vim.v.count
      local bufname = buffer.name()

      if count == 0 then
        bookmark.add_and_save(bufname, win.pos().row)
      else
        bookmark.add_and_save(bufname, count)
      end
    end,
    { desc = "add current buffer" },
  },
  open_dwim_picker = {
    "g<space>",
    function()
      bookmark.run_dwim_picker()
    end,
    { desc = "dwim picker" },
  },
  open_picker = {
    "g.",
    function()
      bookmark.run_picker()
    end,
    { desc = "run picker" },
  },
}

return function()
  Kbd.map_group("bookmark", bookmark.mappings)
end
