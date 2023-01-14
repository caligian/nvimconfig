user.builtin.kbd.noremap_with_options(
{silent=true},
{'n', '<leader>fs', ':w %<CR>', {desc='Save buffer'}},
{'n', '<leader>fe', ':e!<CR>', {desc='Reload buffer'}},
{'n', '<leader>bk', ':hide<CR>', {desc='Hide window'}},
{'n', '<leader>bp', ':bprev<CR>', {desc='Previous buffer'}},
{'n', '<leader>bn', ':bnext<CR>', {desc='Next buffer'}},
{'n', '<leader>b0', ':bfirst', {desc='First buffer'}},
{'n', '<leader>b$', ':blast', {desc='Last buffer'}},
{'n', '<leader>bq', ':bwipeout %<CR>', {desc='Wipeout buffer'}},
{'n', '<leader>tt', ':tabnew<CR>', {desc='New tab'}},
{'n', '<leader>tn', ':tabnext<CR>', {desc='Next tab'}},
{'n', '<leader>tp', ':tabprev<CR>', {desc='Previous tab'}},
{'n', '<leader>te', ':tabedit<CR>', {desc='Open file in new tab'}},
{'n', '<leader>tk', ':tabclose<CR>', {desc='Close tab'}},
{'n', '<leader>t1', ':tabnext 1<CR>', {desc='Tab 1'}},
{'n', '<leader>t2', ':tabnext 2<CR>', {desc='Tab 2'}},
{'n', '<leader>t3', ':tabnext 3<CR>', {desc='Tab 3'}},
{'n', '<leader>t4', ':tabnext 4<CR>', {desc='Tab 4'}},
{'n', '<leader>t5', ':tabnext 5<CR>', {desc='Tab 5'}},
{'n', '<leader>t6', ':tabnext 6<CR>', {desc='Tab 6'}},
{'n', '<leader>t7', ':tabnext 7<CR>', {desc='Tab 7'}},
{'n', '<leader>t8', ':tabnext 8<CR>', {desc='Tab 8'}},
{'n', '<leader>t9', ':tabnext 9<CR>', {desc='Tab 9'}},
{'n', '<leader>t0', ':tabnext 10<CR>', {desc='Tab 10'}},
{'n', '<leader>ws', ':split <bar> wincmd k<CR>', {desc='Split below'}},
{'n', '<leader>wv', ':vsplit <bar> wincmd h<CR>', {desc='Split right'}})

user.builtin.kbd.map({'n', '<leader>w', '<C-w>', {silent=true, desc='Window commands'}})

user.builtin.kbd.noremap({'n', '<leader>fv', function ()
    local s = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    s = table.concat(s, "\n")
    local f, err = loadstring(s)
    if f then
        f()
    else
        print(err)
    end
end, {desc='Lua source buffer'}})

user.builtin.kbd.noremap({'t', '<Esc>', '<C-\\><C-n>', {desc='Go to normal mode'}})
