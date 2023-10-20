require 'core.utils.buffer'

local api = vim.api
local create = api.nvim_create_user_command
local delete = api.nvim_del_user_command
local bufcreate = api.nvim_buf_create_user_command
local bufdelete = api.nvim_buf_del_user_command
local bufget = api.nvim_buf_get_commands
local get = api.nvim_get_commands

command = struct('command', {
    'buffer',
    'name', 
    'callback', 
    'nargs',
    'complete',
    'desc',
    'force',
    'preview',
    'bar',
    'addr',
    'magic',
    'count',
    'reg',
    'browse',
    'confirm',
    'hide',
    'horizontal',
    'keepalt',
    'keepjumps',
    'keepmarks',
    'keeppatterns',
    'leftabove',
    'lockmarks',
    'noautocmd',
    'noswapfile',
    'rightbelow',
    'sandbox',
    'silent',
    'tab',
    'topleft',
    'unsilent',
    'verbose',
    'vertical',
    'validate',
    'post',
})

command.commands = command.commands or {}
command.buffers = command.buffers or {}

function command.get(self, callback)
    local cmd

    if is_struct(self, 'command') then
        cmd = self
    elseif is_number(self) then
        cmd = command.buffers[self]
    else
        cmd = command.commands[self]
    end

    if not cmd then return end
    if callback then return callback(cmd) end
end

function command.nvim_get(name, buf_local)
    local cmds

    if buf_local then
        cmds = bufget({})
    else
        cmds = get {}
    end

    return cmds[name]
end

function command.opts(self)
    return {
        desc = self.desc,
        force = self.force ,
        preview = self.preview,
        bar = self.bar,
        bang = self.bang,
        nargs = self.nargs,
        complete = self.complete,
        addr = self.addr,
        magic = self.magic,
        count = self.count,
        reg = self.reg,
        browse = self.browse,
        confirm = self.confirm,
        hide = self.hide,
        horizontal = self.horizontal,
        keepalt = self.keepalt,
        keepjumps = self.keepjumps,
        keepmarks = self.keepmarks,
        keeppatterns = self.keeppatterns,
        leftabove = self.leftabove,
        lockmarks = self.lockmarks,
        noautocmd = self.noautocmd,
        noswapfile = self.noswapfile,
        rightbelow = self.rightbelow,
        sandbox = self.sandbox,
        silent = self.silent,
        tab = self.tab,
        topleft = self.topleft,
        unsilent = self.unsilent,
        verbose = self.verbose,
        vertical = self.vertical,
    }
end

function command.init_before(name, callback, opts)
    opts = opts or {}
    local validate = opts.validate
    local post = opts.post
    local cb = callback

    if is_callable(cb) then
        callback = function (o)
            if #o.fargs == 0 then
                cb(o)
                return 
            end

            if validate then
                for i=1, #o.fargs do
                    if not validate(o.fargs[i]) then
                        error(name .. ': validation error for arg ' .. i .. ': ' .. o.fargs[i])
                    end
                end
            end

            if post then
                o.fargs = map(o.fargs, post)
            end

            cb(o)
        end
    end

    if opts.buffer then
        local use = opts.buffer == true and buffer.bufnr() or opts.buffer
        bufcreate(use, name, callback, command.opts(opts))
    else
        create(name, callback, command.opts(opts))
    end

    local self = copy(opts)
    self.name = name
    self.callback = callback

    return self
end

function command.init(self)
    if self.buffer then
        command.buffers[self.name] = self
    else
        command.commands[self.name] = self
    end

    return self
end

local function capitalize(name)
    return name:sub(1, 1):upper() .. name:sub(2, #name)
end

function command.map_group(name, spec, compile)
    name = capitalize(name)
    spec = deepcopy(spec)
    local new = {}
    local gopts = spec.opts or {}
    spec.opts = nil

    dict.each(spec, function (key, value)
        key = name .. capitalize(key)
        new[key] = value
        value[2] = merge(copy(value[2] or {}), gopts)

        if not compile then
            new[key] = command(key, unpack(value))
        end
    end)

    return new
end
