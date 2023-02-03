Keybinding({ noremap = true, leader = true }):bind {
    { 'xi', '<cmd>ShellStart<CR>' },
    { 'xs', '<cmd>ShellSplit<CR>' },
    { 'xv', '<cmd>ShellVsplit<CR>' },
    { 'xk', '<cmd>ShellHide<CR>' },
    { 'xq', '<cmd>ShellStop<CR>' },
    { 'xe', '<cmd>ShellSendLine<CR>' },
    { 'xb', '<cmd>ShellSendBuffer<CR>' },
    { 'x.', '<cmd>ShellSendTillPoint<CR>' },
    { 'ri', '<cmd>REPLStart<CR>' },
    { 'rs', '<cmd>REPLSplit<CR>' },
    { 'rv', '<cmd>REPLVsplit<CR>' },
    { 'rk', '<cmd>REPLHide<CR>' },
    { 'rq', '<cmd>REPLStop<CR>' },
    { 're', '<cmd>REPLSendLine<CR>' },
    { 'rb', '<cmd>REPLSendBuffer<CR>' },
    { 'r.', '<cmd>REPLSendTillPoint<CR>' },
}

Keybinding({ noremap = true, leader = true, mode = 'v' }):bind {
    { 're', '<esc><cmd>REPLSendVisualRange<CR>' },
    { 'xe', '<esc><cmd>ShellSendVisualRange<CR>' },
}
