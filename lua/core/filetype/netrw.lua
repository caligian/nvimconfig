local netrw = {}

netrw.autocmds = {
  temp_buffer = function(au)
    buffer.map(Autocmd.buf, "ni", "q", ":hide<CR>")
  end,
}

return netrw
