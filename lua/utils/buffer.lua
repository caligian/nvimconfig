if not Buffer then
    class.Buffer()
end
builtin.makepath(Buffer, 'bufnr')
builtin.makepath(Buffer, 'scratch')

function Buffer._init(self, name, scratch)
    name = name or sprintf('scratch_buffer_%d', #Buffer.scratch + 1)

    local bufnr = vim.fn.bufadd(name)
    self.bufnr = bufnr
    self.name = name

    if name:match('scratch') or scratch then
        builtin.update(Buffer.scratch, { bufnr }, self)

        self.scratch = true
        vim.api.nvim_buf_set_option(bufnr, 'buflisted', false)
        vim.api.nvim_buf_set_option(bufnr, 'modified', false)
        vim.api.nvim_buf_set_option(bufnr, 'buftype', 'nofile')
    end

    builtin.update(Buffer.bufnr, { bufnr }, self)

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
    vim.keymap.set(mode, lhs, callback, builtin.merge_keepleft(opts, {
        buffer = self.bufnr,
    }))
end

function Buffer.noremap(self, mode, lhs, callback, opts)
    vim.keymap.set(mode, lhs, callback, builtin.merge_keepleft(opts, {
        buffer = self.bufnr,
        noremap = true,
    }))
end

function Buffer.split(self, split)
    split = split or 's'

    if split == 's' then
        vim.cmd(builtin.sprintf('split | wincmd j | b %d', self.bufnr))
    elseif split == 'v' then
        vim.cmd(builtin.sprintf('vsplit | wincmd l | b %d', self.bufnr))
    elseif split == 't' then
        vim.cmd(sprintf('tabnew | b %d', self.bufnr))
    end
end

function Buffer.hook(self, event, callback, opts)
    opts = opts or {}

    assert(event)
    assert(callback)

    vim.api.nvim_create_autocmd(event, builtin.merge(opts, {
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

return Buffer
