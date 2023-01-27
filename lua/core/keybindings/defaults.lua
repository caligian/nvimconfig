user.builtin.kbd.noremap_with_options(
{silent=true},
{'n', '\\\\', ':noh<CR>', {desc='No highlight'}},
{'n', '<leader>fs', ':w %<CR>', {desc='Save buffer'}},
{'n', '<leader>fe', ':e!<CR>', {desc='Reload buffer'}},
{'n', '<leader>bk', ':hide<CR>', {desc='Hide window'}},
{'n', '<leader>bp', ':bprev<CR>', {desc='Previous buffer'}},
{'n', '<leader>bn', ':bnext<CR>', {desc='Next buffer'}},
{'n', '<leader>b0', ':bfirst<CR>', {desc='First buffer'}},
{'n', '<leader>b$', ':blast<CR>', {desc='Last buffer'}},
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
{'n', '<leader>wv', ':vsplit <bar> wincmd h<CR>', {desc='Split right'}},
{'n', '<localleader>,', partial(open_scratch_buffer, {split='s', overwrite=true}), {desc='Open scratch buffer in split'}},
{'n', '<localleader><', partial(open_scratch_buffer, {split='v'}), {desc='Open scratch buffer in vsplit'}},
{'n', '<localleader>>', partial(open_scratch_buffer, {split='t'}), {desc='Open scratch buffer in new tab'}},
{'t', '<Esc>', '<C-\\><C-n>', {desc='Go to normal mode'}})

user.builtin.kbd.map({'n', '<leader>w', '<C-w>', {silent=true, desc='Window commands'}})

local function loadstring_from_buffer(opts)
    return function ()
        opts = opts or {}
        if opts.bufnr == true or opts.bufnr == nil then
            opts.bufnr = vim.fn.bufnr()
        end
        local s = {}

        if opts.buffer then
            s = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
        elseif opts.visual then
            s = get_visual_range(opts.bufnr)
        elseif opts.line then
            if opts.line == true then
                s = vim.api.nvim_buf_call(opts.bufnr, function ()
                    return vim.fn.getline('.')
                end)
            else
                s = vim.api.nvim_buf_call(opts.bufnr, function ()
                    return vim.fn.getline(opts.line)
                end)
            end
        elseif opts.till_point then
            s = vim.api.nvim_buf_call(opts.bufnr, function()
                local line = vim.fn.line('.')
                return vim.api.nvim_buf_get_lines(opts.bufnr, 0, line-1, false)
            end)
        end

        local compiled = loadstring(table.concat(ensure_list(s), "\n"))
        if is_type(compiled, 'function') then
           compiled()
        else
            vim.api.nvim_err_writeln(inspect(compiled))
        end
    end
end

user.builtin.kbd.noremap(
{'n', '<leader>eb', loadstring_from_buffer {buffer=true}, {desc='Lua source buffer'}},
{'n', '<leader>ee', loadstring_from_buffer {line=true}, {desc='Lua source current line'}},
{'n', '<leader>e.', loadstring_from_buffer {till_point=true}, {desc='Lua source till point'}},
{'v', '<leader>ee', loadstring_from_buffer {visual=true}, {desc='Lua source visual range'}})
