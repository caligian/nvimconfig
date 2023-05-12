local function delete_and_hide(wipeout)
  local bufname = vim.fn.bufname(vim.fn.bufnr())
  if wipeout then
    vim.cmd(":Bwipeout " .. bufname)
  else
    vim.cmd(":Bdelete " .. bufname)
  end
  local tab = vim.fn.tabpagenr()
  local n_wins = #(vim.fn.tabpagebuflist(tab))
  if n_wins > 1 then vim.cmd ":hide" end
end

plugin.bbye.methods = {
  delete = delete_and_hide,
  wipeout = function() delete_and_hide(true) end,
}

plugin.bbye.kbd = {
  noremap = true,
  leader = true,
  { "bq", delete_and_hide, { desc = "Delete buffer", name = "delete_buffer" } },
  {
    "bQ",
    function() delete_and_hide(true) end,
    { desc = "Wipeout buffer", name = "Wipeout buffer" },
  },
}
