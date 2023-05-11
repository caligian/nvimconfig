plugin.dispatch.kbd = {
  noremap = true,
  leader = true,
  {
    "cb",
    function()
      local ft = vim.bo.filetype
      if string.isblank(ft) then
        return
      end
      local compiler = Filetype.ft[ft].build
      if not compiler then
        utils.nvimerr("No compiler defined for " .. ft)
        return
      end
      vim.cmd("Dispatch " .. compiler .. " %:p")
    end,
    "n",
    { noremap = true, desc = "Build file" },
  },
  {
    "cq",
    ":Copen<CR>",
    "n",
    { desc = "Open qflist", noremap = true },
  },
  {
    "ct",
    function()
      local ft = vim.bo.filetype
      if string.isblank(ft) then
        return
      end
      local compiler = Filetype.ft[ft].test
      if not compiler then
        utils.nvimerr("No compiler defined for " .. ft)
        return
      end
      vim.cmd("Dispatch " .. compiler .. " %:p")
    end,
    "n",
    { noremap = true, desc = "Test file" },
  },
  {
    "cc",
    function()
      local ft = vim.bo.filetype
      if string.isblank(ft) then
        return
      end
      local compiler = Filetype.ft[ft].compile
      if not compiler then
        utils.nvimerr("No compiler defined for " .. ft)
        return
      end
      vim.cmd("Dispatch " .. compiler .. " %:p")
    end,
    "n",
    { noremap = true, desc = "Compile file" },
  },
}
