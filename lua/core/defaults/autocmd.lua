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

Autocmd("BufAdd", {
  pattern = "*",
  callback = function()
    local bufnr = vim.fn.bufnr()
    array.each(dict.values(user.temp_buffer_patterns), function(pat)
      if is_callable(pat) then
        if pat(bufnr) then
          vim.keymap.set({ "n", "i" }, "q", ":hide<CR>", { buffer = vim.fn.bufnr() })
        end
      elseif is_string(pat) then
        if vim.api.nvim_buf_get_name(bufnr):match(pat) then
          vim.keymap.set({ "n", "i" }, "q", ":hide<CR>", { buffer = bufnr })
        end
      end
    end)
  end,
})
