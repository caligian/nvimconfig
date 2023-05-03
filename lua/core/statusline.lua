local statusline = {
  '%y%q',
  '%f%m %r',
}

vim.o.statusline = array.join(statusline, ' ')

