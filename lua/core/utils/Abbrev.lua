require "core.utils.autocmd"
require "core.utils.buffer"

Abbrev = Abbrev or struct("Abbrev", { "mode", "cmd", "buffer", "lhs", "rhs", "autocmd", "autocmd_id", 'pattern', 'event' })
Abbrev.buffers = Abbrev.buffers or {}
Abbrev.rhs = Abbrev.rhs or {}
Abbrev.abbrevs = {}

local function get_id()
    return #(keys(Abbrev.rhs)) + 1
end

local function create_vim_fn()
    local id = get_id()
    local fn_name = 'LuaAbbrevCallback' .. id
    local fn = sprintf([[function %s()
        return luaeval('Abbrev.rhs[%d]()')
    endfunction]], fn_name, id)

    vim.cmd(fn)

    return id, fn_name
end

local function register_fn(rhs)
    local id, vim_fn_name = create_vim_fn()
    Abbrev.rhs[id] = rhs

    return (vim_fn_name .. '()')
end

local function apply_for_buffer(self)
    local bufnr = self.buffer
    local cmd = self.cmd
    local pattern = self.pattern
    local event = self.event
    local function callback(opts)
        local bufnr = opts.buf
        local id = opts.id
        Abbrev.buffers[bufnr] = Abbrev.buffers[bufnr] or {}
        Abbrev.buffers[bufnr][id] = self
        buffer.call(opts.buf, function () 
            vim.cmd(cmd) 
        end)
    end

    if bufnr then
        self.autocmd = autocmd.map("BufEnter", {
            buffer = bufnr,
            callback = callback,
        })
    elseif event and pattern then
        self.autocmd = autocmd.map(event, {
            buffer = buffer.bufnr(),
            callback = callback,
        })
    elseif event then
        self.autocmd = autocmd.map(event, {
            buffer = buffer.bufnr(),
            callback = callback,
        })
    elseif pattern then
        self.autocmd = autocmd.map("BufEnter", {
            pattern = pattern,
            callback = callback,
        })
    end

    self.autocmd_id = self.autocmd.id

    return self
end

function Abbrev.init_before(lhs, rhs, opts)
    opts = opts or {}
    local noremap = opts.noremap
    local mode = opts.mode
    local buf = opts.buffer
    local is_cmd = opts.cmd
    local pattern = opts.pattern
    local event = opts.event
    local expr = opts.expr
    local cmd
    local self = {}

    if mode == "c" then
        cmd = "c"
    elseif mode == "i" then
        cmd = "i"
    else
        cmd = ""
    end

    if noremap then
        cmd = cmd .. "noreabbrev"
    else
        cmd = cmd .. "abbrev"
    end

    local expr_is_callable = is_callable(rhs)
    if expr or expr_is_callable or is_cmd then
        cmd = cmd .. ' ' .. '<expr>'
    end

    local buf_is_number = is_number(buf)
    if buf or pattern then
        cmd = cmd .. ' ' .. '<buffer>'
    end

    if expr_is_callable then
        cmd = cmd .. ' ' .. lhs .. ' ' .. register_fn(rhs)
    else
        cmd = cmd .. ' ' .. lhs .. ' ' .. rhs
    end

    self.cmd = cmd
    self.buffer = buf
    self.pattern = pattern
    self.event = event

    if buf_is_number or pattern or event then
        apply_for_buffer(self)
    else
        vim.cmd(self.cmd)
    end

    self.mode = mode
    self.noremap = noremap
    self.expr = expr
    self.cmd = cmd
    self.lhs = lhs
    self.rhs = rhs

    return self
end

function Abbrev.exists(self)
    local out

    if self.buffer then
        if is_number(self.buffer) then
            out = buffer.call(self.buffer, function ()
                return exec('abbrev <buffer> ' .. self.lhs)
            end)
        else
            out = exec('abbrev <buffer> ' .. self.lhs)
        end
    else
        out = exec('abbrev ' .. self.lhs)
    end

    if strmatch(out, 'No abbreviation found') then
        return false
    else
        return true
    end
end

function Abbrev.del(self)
    if not Abbrev.exists(self) then
        return
    end

    local cmd = ''

    if mode == "c" then
        cmd = "c"
    elseif mode == "i" then
        cmd = "i"
    else
        cmd = ""
    end

    cmd = cmd .. 'unabbrev'
    local bufnr = self.buffer
    if bufnr then
        cmd = cmd .. ' ' .. '<buffer>'
    end
    
    local lhs = self.lhs
    cmd = cmd .. ' ' .. lhs

    if self.autocmd then
        autocmd.disable(self.autocmd)
        buffer.call(bufnr, function () exec(cmd) end)
    else
        exec(cmd)
    end

    return true
end

function Abbrev.map(...)
    local args = {...}

    if #args == 1 then
        return map(args[1], function (x) return Abbrev(unpack(x)) end)
    else
        return Abbrev(...)
    end
end
