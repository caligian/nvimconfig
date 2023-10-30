require "core.utils.terminal"
require "core.utils.kbd"
require 'core.utils.filetype'

REPL = REPL or struct("REPL", {
    'terminals',
    "load_file",
    "on_input",
    "connected",
    "filetype",
    'buffers',
    'filetype',
})

REPL.repls = REPL.repls or {}

function REPL.init(self, ft, opts)
    ft = ft or buffer.filetype(buffer.bufnr())

    if not filetype.attrib(ft, 'repl') then
        error('no spec exists for ' .. dump(ft))
    elseif REPL.repls[ft] then
        return REPL.repls[ft]
    end

    opts = opts or {}

    self.filetype = ft
    self.terminals = {buffer = {}, workspace = {}, single = {}}
    self.buffers = {}
    self.connected = {}
    self.on_input = opts.on_input
    self.load_file = opts.load_file

    REPL.repls[ft] = self
    return self
end

function REPL.buffer_get(bufnr, callback)
    bufnr = buffer.bufnr(bufnr)
    local ft = buffer.filetype(bufnr)
    local exists = REPL.repls[ft] and REPL.repls[ft].connected[bufnr]

    if exists and terminal.is_running(exists) then
        if callback then
            return callback(exists)
        end

        return exists
    end

    return false
end

function REPL.register(self, buf, opts)
    local exists = REPL.buffer_get(buf)
    if exists then return exists end

    local bufnr = buffer.bufnr(buf)
    local ft = buffer.filetype(buf)

    if ft ~= self.filetype then
        error('expected ' .. self.filetype .. ' buffer, got ' .. ft)
    end

    local cmd, ws = filetype.command(ft, 'repl')(buffer.name(bufnr))
    opts = opts or {}

    self.connected[bufnr] = terminal(cmd, {
        on_input = self.on_input,
        load_file = self.load_file,
    })

    return self.connected[bufnr]
end

function REPL.set_mappings(mappings, compile)
    mappings = mappings or REPL.mappings or {}
    if is_empty(mappings) then return end

    return kbd.map_group('REPL', mappings, compile)
end

function REPL.set_autocmds(autocmds, compile)
    autocmds = autocmds or REPL.autocmds or {}
    if is_empty(autocmds) then return end

    return autocmd.map_group('REPL', autocmds, compile)
end

local start = REPL.start
function REPL.start(self, callback)
    self = REPL.get(self)

    if not self then
        return 
    elseif REPL.is_running(self) then
        return self
    end

    if self.connected then
        vim.api.nvim_create_autocmd('BufWipeout', {
            pattern = '<buffer=' .. self.connected .. '>',
            desc = 'stop repl for buffer ' .. self.connected,
            callback = function () REPL.stop(self) end,
            once = true,
        })
    end

    return start(self)
end

function REPL.set_mappings(mappings)
    mappings = mappings or REPL.mappings
    return kbd.map_group("REPL", mappings)
end

function REPL.set_autocmds(autocmds)
    autocmds = autocmds or REPL.autocmds
    return autocmd.map_group("REPL", REPL.autocmds)
end

local stop = REPL.stop
function REPL.stop(self)
    self = REPL.get(self)
    if self then return stop(self) end
end

function REPL.stop_all()
    each(values(REPL.repls), REPL.stop)
    each(values(REPL.single_repls), REPL.stop)
end

function REPL.set_commands(commands)
    teach(commands or REPL.commands, function(name, spec)
        REPL.command_group:add(name, unpack(spec))
    end)

    return REPL.command_group
end

local if_running = REPL.if_running
function REPL.if_running(self, callback)
    self = REPL.get(self)

    if not self then
        return
    elseif if_running(self) then
        return callback(self)
    end
end

each({
    "send_current_line",
    "send_buffer",
    "send_till_cursor",
    "send_textsubject_at_cursor",
    "send_node_at_cursor",
    "send_range",
}, function (fun)
    local current = REPL[fun]
    REPL[fun] = function (self, src_bufnr)
        self = REPL.get(self)
        if not self then
            return
        elseif src_bufnr then
            return current(self, src_bufnr)
        elseif self.connected then
            return current(self, self.connected)
        else
            return current(self, buffer.bufnr())
        end
    end
end)

function REPL.load_commands(self, spec, compile)
    spec = spec or self.commands
    if not spec or is_empty(spec) then return end

    return command.map_group('repl', spec, compile)
end
