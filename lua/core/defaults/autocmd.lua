Autocmd("TextYankPost", {
  name = "highlight_on_yank",
  pattern = "*",
  callback = function()
    vim.highlight.on_yank { timeout = 100 }
  end,
})

Autocmd("BufAdd", {
  name = "textwidth_colorcolumn",
  pattern = "*",
  callback = function()
    buffer.setwinopt(vim.fn.bufnr(), "colorcolumn", "+2")
  end,
})

Autocmd("BufAdd", {
  name = "i3config_extension",
  pattern = "*i3",
  callback = function()
    vim.cmd "set ft=i3config"
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
  end,
})

Autocmd("BufAdd", {
  name = "txt_is_help",
  pattern = "*txt",
  callback = "set ft=help",
})

Autocmd("BufAdd", {
  name = "quit_temp_buffer_with_q",
  pattern = "*",
  callback = function()
    local bufnr = vim.fn.bufnr()
    array.each(dict.values(user.temp_buffer_patterns), function(pat)
      if is_callable(pat) then
        if pat(bufnr) then
          vim.keymap.set({ "n", "i" }, "q", ":hide<CR>", { buffer = bufnr })
        end
      elseif is_string(pat) then
        if vim.api.nvim_buf_get_name(bufnr):match(pat) then
          vim.keymap.set({ "n", "i" }, "q", ":hide<CR>", { buffer = bufnr })
        end
      elseif is_table(pat) then
        local ft = pat.ft or pat.filetype
        if ft and vim.bo.filetype == ft then
          vim.keymap.set({ "n", "i" }, "q", ":hide<CR>", { buffer = bufnr })
        elseif pat.bufname and pat.bufname:match(buffer.name(bufnr)) then
          vim.keymap.set({ "n", "i" }, "q", ":hide<CR>", { buffer = bufnr })
        elseif pat.bufnr and pat.bufnr == bufnr then
          vim.keymap.set({ "n", "i" }, "q", ":hide<CR>", { buffer = bufnr })
        end
      end
    end)
  end,
})
