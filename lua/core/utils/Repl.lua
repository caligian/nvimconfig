require "core.utils.Terminal"
require "core.utils.Filetype"
require "core.utils.kbd"
require 'core.utils.Command'

Repl = Repl or struct.new("Repl", {
    "single",
    "pid",
    "id",
    "cmd",
    "opts",
    "load_file",
    "on_input",
    "bufnr",
    "connected",
    "ft",
})

dict.each(Terminal, function (k, v)
    if k ~= 'new' then Repl[k] = v end
end)

Repl.single_repls = Repl.single_repls or {}
Repl.repls = Repl.repls or {}
Repl.exception = {}
Repl.exception.no_command = exception "no command for filetype"
Repl.commands = {}

local function get_command(ft)
    local repl = Filetype.get(ft)
    if not repl then
        error('no command found for ' .. ft)
    end

    repl = repl.repl
    local out = { ft = ft }

    if is_table(repl) then
        repl = copy(repl)
        out.cmd = repl.cmd or repl[1]
        assert(out.cmd, "no command found for " .. ft)

        repl.cmd = nil
        shift(repl)

        out.load_file = repl.load_file
        out.on_input = repl.on_input
        repl.load_file = nil
        repl.on_input = repl.on_input
        out.opts = repl
    else
        out.cmd = repl
        out.opts = {}
    end

    return out
end

function Repl.get(ft, callback)
    if is_struct(ft, 'Repl') then
        return ft
    end

    local exists

    if is_number(ft) then
        exists = Repl.repls[ft]
    else
        exists = Repl.single_repls[ft]
    end

    if not exists then
        return
    end

    return callback and callback(exists) or exists
end

function Repl.load_mappings(mappings, compile)
    mappings = mappings or Repl.mappings or {}
    if is_empty(mappings) then return end

    return kbd.map_group('Repl', mappings, compile)
end

function Repl.load_autocmds(autocmds, compile)
    autocmds = autocmds or Repl.autocmds or {}
    if is_empty(autocmds) then return end

    return autocmd.map_group('Repl', autocmds, compile)
end

function Repl.load_commands(commands, compile)
    commands = commands or Repl.commands or {}
    if is_empty(commands) then return end

    return Command.map_group('Repl', commands, compile)
end

function Repl.init_before(ft_or_bufnr, opts)
    local attribs = {}

    if is_number(ft_or_bufnr) then
        assert(buffer.exists(ft_or_bufnr), "expected valid buffer, got " .. ft_or_bufnr)

        local ft = buffer.option(ft_or_bufnr, "filetype")
        assert(#ft > 0, "invalid filetype obtained")

        local bufnr = ft_or_bufnr
        attribs.ft = ft
        attribs.connected = bufnr
    else
        attribs.ft = ft_or_bufnr
    end

    merge(attribs, get_command(attribs.ft))

    if opts then
        merge(attribs.opts, opts)
    end

    return attribs
end

function Repl.init(self)
    local exists = self.connected and Repl.repls[self.bufnr] or Repl.single_repls[self.ft]

    if exists and pid_exists(exists.pid) then
        return exists
    end

    merge(self, Terminal(self.cmd, self.opts))

    if self.connected then
        Repl.repls[self.connected] = self
    else
        Repl.single_repls[self.ft] = self
    end

    mtset(self, 'name', 'Repl')

    return self
end

local start = Repl.start
function Repl.start(self, callback)
    self = Repl.get(self)

    if not self then
        return 
    elseif Repl.is_running(self) then
        return self
    end

    if self.connected then
        vim.api.nvim_create_autocmd('BufWipeout', {
            pattern = '<buffer=' .. self.connected .. '>',
            desc = 'stop repl for buffer ' .. self.connected,
            callback = function () Repl.stop(self) end,
            once = true,
        })
    end

    return start(self)
end

function Repl.set_mappings(mappings)
    mappings = mappings or Repl.mappings
    return kbd.map_group("Repl", mappings)
end

function Repl.set_autocmds(autocmds)
    autocmds = autocmds or Repl.autocmds
    return autocmd.map_group("Repl", Repl.autocmds)
end

local stop = Repl.stop
function Repl.stop(self)
    self = Repl.get(self)
    if self then return stop(self) end
end

function Repl.stop_all()
    array.each(values(Repl.repls), Repl.stop)
    array.each(values(Repl.single_repls), Repl.stop)
end

function Repl.set_commands(commands)
    dict.each(commands or Repl.commands, function(name, spec)
        Repl.command_group:add(name, unpack(spec))
    end)

    return Repl.command_group
end

local if_running = Repl.if_running
function Repl.if_running(self, callback)
    self = Repl.get(self)

    if not self then
        return
    elseif if_running(self) then
        return callback(self)
    end
end

local send_current_line = Repl.send_current_line
local send_buffer = Repl.send_buffer
local send_till_cursor = Repl.send_till_cursor
local send_textsubject_at_cursor = Repl.send_textsubject_at_cursor
local send_range = Repl.send_range
local send_node_at_cursor = Repl.send_node_at_cursor

array.each({
    "send_current_line",
    "send_buffer",
    "send_till_cursor",
    "send_textsubject_at_cursor",
    "send_node_at_cursor",
    "send_range",
}, function (fun)
    local current = Repl[fun]
    Repl[fun] = function (self, src_bufnr)
        self = Repl.get(self)
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
