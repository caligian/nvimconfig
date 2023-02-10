Keybinding.bind(
  { leader = true, noremap = true },
  { 'xi', '<cmd>StartREPL sh<CR>' },
  { 'xs', '<cmd>SplitREPL sh<CR>' },
  { 'xv', '<cmd>VsplitREPL sh<CR>' },
  { 'xk', '<cmd>HideREPL sh<CR>' },
  { 'xq', '<cmd>StopREPL sh<CR>' },
  { 'xe', '<cmd>SendLineREPL sh<CR>' },
  { 'xb', '<cmd>SendBufferREPL sh<CR>' },
  { 'x.', '<cmd>SendTillPointREPL sh<CR>' },
  { 'ri', '<cmd>StartREPL<CR>' },
  { 'rs', '<cmd>SplitREPL<CR>' },
  { 'rv', '<cmd>VsplitREPL<CR>' },
  { 'rk', '<cmd>HideREPL<CR>' },
  { 'rq', '<cmd>StopREPL<CR>' },
  { 'rQ', REPL.stopall, 'Stop all REPLs' },
  { 're', '<cmd>SendLineREPL<CR>' },
  { 'rb', '<cmd>SendBufferREPL<CR>' },
  { 'r.', '<cmd>SendTillPointREPL<CR>' }
)

Keybinding.noremap('v', '<leader>re', '<cmd>SendRangeREPL<CR>')
Keybinding.noremap('v', '<leader>xe', '<cmd>SendRangeREPL sh<CR>')
