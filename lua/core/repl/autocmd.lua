Autocmd(
  'QuitPre',
  {
    pattern = '*',
    callback = require('core.repl.REPL').stopall,
    name = 'stop_repls_at_exit'
  }
)
