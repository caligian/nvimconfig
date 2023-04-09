Autocmd("TextYankPost", {
  pattern = "*",
  callback = function()
    vim.highlight.on_yank { timeout = 200 }
  end,
})

Autocmd("BufEnter", {
  pattern = "*i3",
  callback = function()
    vim.cmd "set ft=i3config"
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
  end,
})

Autocmd("BufEnter", {
  pattern = "*txt",
  callback = "set ft=help",
})

Autocmd("BufEnter", {
  pattern = ".config/nvim/doc/*txt",
  callback = 'let b:_tag_prefix = "doom"',
})

-- Autocmd('BufAdd', {
--   pattern = '*',
--   callback = function()
-- 	  if vim.fn.bufname('%') == '' then
-- 		  vim.cmd 'bdelete'
-- 	  end
--   end
-- })

Autocmd('BufAdd', {
  pattern = '*',
  callback = function ()
    Array.each(Dict.values(user.temp_buffer_patterns), function (pat)
      if is_callable(pat) then
        if pat(vim.fn.bufnr()) then
          vim.keymap.set({'n', 'i'}, 'q', ':hide<CR>', {buffer=vim.fn.bufnr()})
        end
      elseif is_string(pat) and vim.fn.bufname():match(pat) then
          vim.keymap.set({'n', 'i'}, 'q', ':hide<CR>', {buffer=vim.fn.bufnr()})
      end
    end)
  end
})
