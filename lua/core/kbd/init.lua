Keybinding.id = Keybinding.id
Keybinding.buffer = Keybinding.buffer

-- opts [table]
-- keys:
-- mode table[string] | string
-- event table[string] | string
-- pattern table[string] | string
-- leader boolean
-- localleader boolean
function Keybinding._init(self, opts)
    opts = opts or {}

    for k, v in pairs(opts) do
        if builtin.match(k, 'mode', 'event', 'pattern', 'leader', 'localleader', 'opts', 'once', 'nested') then
            self[k] = v
        end
    end

    self.mode = self.mode or 'n'
    self.event = self.event == nil and false or self.event
    self.pattern = self.pattern == nil and false or self.pattern
    self.leader = self.leader == nil and false or self.leader
    self.localleader = self.localleader == nil and false or self.localleader
    self.opts = self.opts or {}

    return self
end

local function update(self)
    local lhs = self.lhs
    local bufnr = self.bufnr

    for _, i in ipairs(builtin.ensure_list(self.mode)) do
        builtin.makepath(Keybinding, i, lhs)

        if bufnr then
            builtin.append(Keybinding[i][lhs], self)
            builtin.makepath(Keybinding.buffer, bufnr, i, lhs)
            builtin.append(Keybinding.buffer[bufnr][i][lhs], self)
        else
            builtin.append(Keybinding[i][lhs], self)
        end
    end

    return self
end

local function bind(self, lhs, callback, opts)
    -- Every keybinding is a new one
    self = vim.deepcopy(self)

    if opts then
        builtin.merge(self.opts, opts)
    end

    self.lhs = lhs
    self.callback = callback
    self.enabled = false

    assert(callback, 'No callback provided')
    assert(lhs, 'No LHS provided')

    if self.leader then
        lhs = '<leader>' .. lhs
    elseif self.localleader then
        lhs = '<localleader>' .. lhs
    end

    if self.pattern then
        self.event = self.event or 'BufEnter'
        local a = user.autocmd(lhs .. '_' .. #Autocmd.group, true)
        a:create(self.event, self.pattern, function()
            self.enabled = true
            self.bufnr = vim.fn.bufnr()
            vim.keymap.set(self.mode, lhs, self.callback, self.opts)
        end, { once = self.once, nested = self.nested, name = lhs })
    else
        self.enabled = true
        vim.keymap.set(self.mode, lhs, callback, self.opts)
    end

    self.lhs = lhs
    update(self)

    return self
end

function Keybinding.bind(self, keys)
    local out = {}

    for _, k in ipairs(keys) do
        assert(types.is_type(k, 'table'))
        assert(#k >= 2, 'Need {lhs, callback, opt}')

        local l, cb, opts = unpack(k)
        opts = opts or {}
        out[l] = bind(self, l, cb, opts)
    end

    return out
end

function Keybinding.disable(self)
    if not self.enabled then
        return self
    end

    local lhs = self.lhs
    local bufnr = self.bufnr

    for _, m in ipairs(self.mode) do
        if bufnr then
            vim.api.nvim_buf_del_keymap(bufnr, m, lhs)
        else
            vim.api.nvim_del_keymap(m, lhs)
        end
    end

    self.enabled = false
    return self
end

function Keybinding.map(mode, lhs, callback, opts)
    local options = {
        mode = mode,
        opts = opts,
    }
    return Keybinding(options):bind({ { lhs, callback } })
end

function Keybinding.noremap(mode, lhs, callback, opts)
    opts.noremap = opts.noremap == nil and false or opts.noremap
    return Keybinding.map(mode, lhs, callback, opts)
end
