Keybinding({ noremap = true, leader = true }):bind({
	{ 'xi', '<cmd>StartREPL sh<CR>' },
	{ 'xs', '<cmd>SplitREPL sh<CR>' },
	{ 'xv', '<cmd>VsplitREPL sh<CR>' },
	{ 'xk', '<cmd>HideREPL sh<CR>' },
	{ 'xq', '<cmd>StopREPL sh<CR>' },
	{ 'xQ', '<cmd>StopAllREPL sh<CR>' },
	{ 'xe', '<cmd>SendLineREPL sh<CR>' },
	{ 'xb', '<cmd>SendBufferREPL sh<CR>' },
	{ 'x.', '<cmd>SendTillPointREPL sh<CR>' },
	{ 'xe', '<cmd>SendRangeREPL sh<CR>', { mode = 'v' } },
	{ 'ri', '<cmd>StartREPL<CR>' },
	{ 'rs', '<cmd>SplitREPL<CR>' },
	{ 'rv', '<cmd>VsplitREPL<CR>' },
	{ 'rk', '<cmd>HideREPL<CR>' },
	{ 'rq', '<cmd>StopREPL<CR>' },
	{ 'rQ', '<cmd>StopAllREPL<CR>' },
	{ 're', '<cmd>SendLineREPL<CR>' },
	{ 'rb', '<cmd>SendBufferREPL<CR>' },
	{ 'r.', '<cmd>SendTillPointREPL<CR>' },
	{ 're', '<cmd>SendRangeREPL<CR>', { mode = 'v' } },
})
