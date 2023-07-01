local bbye = plugin.get 'bbye'

function bbye.delete_and_hide(wipeout)
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

bbye.mappings = {
  bbye = {
    opts = {noremap=true, leader=true},
    delete_buffer = { "bq", bbye.delete_and_hide, { desc = "Delete buffer" } },
    wipeout_buffer = {
      "bQ",
      function() bbye.delete_and_hide(true) end,
      { desc = "Wipeout buffer" },
    }
  }
}
