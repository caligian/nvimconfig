Keybinding({
    event = 'BufNew', 
    pattern = {'*.lua', '*.vim'},
    noremap = true, 
    leader = true
}):bind {
    {'fv', ':w <bar> :source % <CR>'}
}
