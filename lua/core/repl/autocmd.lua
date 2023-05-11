Autocmd(
  'QuitPre',
  {
    pattern = '*',
    callback = function () require('core.utils.REPL').stopall() end,
    name = 'stop_repls_at_exit'
  }
)
