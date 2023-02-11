Autocmd('VimLeave', {
  pattern = '*',
  callback = REPL.stopall,
})
