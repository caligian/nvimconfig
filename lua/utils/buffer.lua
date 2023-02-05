class 'Buffer'

Buffer.bufnr = Buffer.bufnr or {}
Buffer.scratch = Buffer.scratch or {}
local scratch_n = 0
local input_buffer_n = 0

V.makepath(Buffer, 'bufnr')
V.makepath(Buffer, 'scratch')

function Buffer._init(self, name, scratch)
    local bufnr = vim.fn.bufnr(name)

    if bufnr ~= -1 then
        if not Buffer.bufnr[bufnr] then
            if name:match('scratch_buffer_') then
                return Buffer(name, true)
            else
                return Buffer(name)
            end
        else
            return Buffer.bufnr[bufnr]
        end
    end

    name = name or sprintf('scratch_buffer_%d', #scratch_n + 1)

    local bufnr = vim.fn.bufadd(name)
    self.bufnr = bufnr
    self.name = name

    if name:match('scratch_buffer_[0-9]?') or scratch then
        V.update(Buffer.scratch, { bufnr }, self)

        self.scratch = true
        vim.api.nvim_buf_set_option(bufnr, 'buflisted', false)
        vim.api.nvim_buf_set_option(bufnr, 'modified', false)
        vim.api.nvim_buf_set_option(bufnr, 'buftype', 'nofile')
    end

    V.update(Buffer.bufnr, { bufnr }, self)

    return self
end

function Buffer.getopt(self, opt)
    local _, out = pcall(vim.api.nvim_buf_get_option, self.bufnr, opt)

    if out then
        return out
    end
end

function Buffer.getvar(self, var)
    local _, out = pcall(vim.api.nvim_buf_get_var, self.bufnr, var)

    if out then
        return out
    end
end

function Buffer.setvar(self, vars)
    vars = vars or {}
    for key, value in pairs(vars) do
        vim.api.nvim_buf_set_var(self.bufnr, key, value)
    end
end

function Buffer.setopt(self, opts)
    opts = opts or {}
    for key, value in pairs(opts) do
        vim.api.nvim_buf_set_option(self.bufnr, key, value)
    end
end

function Buffer.map(self, mode, lhs, callback, opts)
    vim.keymap.set(mode, lhs, callback, V.merge_keepleft(opts, {
        buffer = self.bufnr,
    }))
end

function Buffer.noremap(self, mode, lhs, callback, opts)
    vim.keymap.set(mode, lhs, callback, V.merge_keepleft(opts, {
        buffer = self.bufnr,
        noremap = true,
    }))
end

function Buffer.split(self, split)
    split = split or 's'

    if split == 's' then
        vim.cmd(V.sprintf('split | wincmd j | b %d', self.bufnr))
    elseif split == 'v' then
        vim.cmd(V.sprintf('vsplit | wincmd l | b %d', self.bufnr))
    elseif split == 't' then
        vim.cmd(sprintf('tabnew | b %d', self.bufnr))
    end
end

function Buffer.hook(self, event, callback, opts)
    opts = opts or {}

    assert(event)
    assert(callback)

    vim.api.nvim_create_autocmd(event, V.merge(opts, {
        pattern = sprintf('<buffer=%d>', self.bufnr),
        callback = callback,
    }))
end

function Buffer.hide(self)
    local winid = vim.fn.bufwinid(self.bufnr)

    if winid ~= -1 then
        vim.fn.win_gotoid(winid)
        vim.cmd('hide')
    end
end

function Buffer.is_visible(self)
    local winid = vim.fn.bufwinid(self.bufnr)

    return winid ~= -1
end

function Buffer.lines(self, startrow, tillrow)
    return vim.api.nvim_buf_get_lines(self.bufnr, startrow, tillrow, false)
end

function Buffer.text(self, start, till, repl)
    assert(types.is_type(start, 'table'))
    assert(types.is_type(till, 'table'))
    assert(repl)

    if types.is_type(repl) == 'string' then
        repl = vim.split(repl, "[\n\r]")
    end

    local a, b = unpack(start)
    local m, n = unpack(till)

    return vim.api.nvim_buf_get_text(self.bufnr, a, m, b, n, repl)
end

function Buffer.setlines(self, startrow, endrow, repl)
    assert(startrow)
    assert(endrow)

    if types.is_type(repl, 'string') then
        repl = vim.split(repl, "[\n\r]")
    end

    vim.api.nvim_buf_set_lines(self.bufnr, startrow, endrow, false, repl)
end

function Buffer.set(self, start, till, repl)
    assert(types.is_type(start, 'table'))
    assert(types.is_type(till, 'table'))

    vim.api.nvim_buf_set_text(self.bufnr, start[1], till[1], start[2], till[2], repl)
end

function Buffer.load(self)
    vim.fn.bufload(self.bufnr)
end

function Buffer.loaded(self)
    return vim.fn.bufloaded(self.bufnr) ~= 0
end

function Buffer.switch_to_scratch(default)
    if default then
        vim.cmd('b scratch_buffer')
    else
        vim.ui.select(V.map(vim.fn.bufname, V.keys(Buffer.scratch)), {
            prompt = 'Switch to scratch buffer',
        }, function(b)
            vim.cmd('b ' .. b)
        end)
    end
end

function Buffer.open_scratch(name, split)
    name = name or 'scratch_buffer'
    local buf = Buffer(name, true)
    buf:split(split or 's')

    return buf
end

function Buffer.call(self, cb)
    return vim.api.nvim_buf_call(self.bufnr, cb)
end

function Buffer.input(name, text, cb, split, trigger_keys)
    if not name then
        name = 'input_buffer_' .. input_buffer_n
        input_buffer_n = input_buffer_n + 1
    end

    if V.is_type(text, 'string') then
        text = vim.split(text, "\n")
    end

    local buf = Buffer(name, true)
    buf:setlines(0, -1, text)
    buf:split(split)

    trigger_keys = trigger_keys or '<C-c><C-c>'
    buf:map('n', trigger_keys, function() cb(buf:lines(0, -1)) end, { noremap = true })
end

function Buffer.getmap(self, mode, lhs)
    return V.buffer_has_keymap(self.bufnr, mode, lhs)
end

function Buffer.visualrange(self)
    return V.get_visual_range(self.bufnr)
end

return Buffer
