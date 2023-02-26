Autocmd.defaults.highlight_on_yank = Autocmd("TextYankPost", {
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})

Autocmd.defaults.i3config = Autocmd('BufEnter', {
  pattern = '*i3',
  callback = function ()
    vim.cmd('set ft=i3config')
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
  end,
})
