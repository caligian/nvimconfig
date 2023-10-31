require "core.utils.terminal"
require "core.utils.kbd"
require 'core.utils.filetype'

REPL = REPL or struct("REPL", {
    'pid',
    "id",
    "cmd",
    "opts",
    "load_file",
    "on_input",
    "buffer",
    'type',
    'workspace',
    'filetype',
    'buf',
})

merge(REPL, terminal)

REPL.terminals = nil
REPL.repls = REPL.repls or {buffer = {}, workspace = {}, filetype = {}}
REPL.wslookup = REPL.wslookup or {} 

local function buf2ws(buf)
    buf = buffer.bufnr(buf)
    local ws = REPL.wslookup[buf]

    if not ws then return end
    if ws and path.exists(ws) then return ws end

    ws = filetype.workspace(buffer.name(buf))
    if not ws then return end

    REPL.wslookup[buf] = ws

    return ws
end

function REPL.exists(what, arg, callback, orelse)
    if what == 'b' then
        what = 'buffer'
    elseif what == 'w' then
        what = 'workspace'
    else
        what = 'filetype'
    end

    local check_in = REPL.repls[what]
    assert(is_table(check_in), 'expected any of b, w, f')

    local exists = check_in[arg]
    if not exists or not terminal.is_running(exists) then
        if orelse then return orelse() end
        return
    elseif callback then
        return callback(exists)
    end

    return exists
end

function REPL.bufexists(buf, callback, orelse)
    return REPL.exists('b', buf, callback, orelse)
end

function REPL.ftexists(ft, callback, orelse)
    return REPL.exists('f', ft, callback, orelse)
end

function REPL.wsexists(ws, callback, orelse)
    return REPL.exists('w', ws, callback, orelse)
end

function REPL.if_type(self, callbacks)
    local tp = self.type
    local is_ft = tp == 'filetype'
    local is_buf = tp == 'buffer'
    local is_ws = tp == 'workspace'
    callbacks = callbacks or {}
    local cb = callbacks[tp]

    local wsobj = is_ws and REPL.wsexists(self.workspace)
    if wsobj then
        if cb then return cb(wsobj) end
        return wsobj
    end

    local ftobj = is_ft and REPL.ftexists(self.filetype)
    if ftobj then
        if cb then return cb(ftobj) end
        return ftobj
    end

    local bufobj = is_buf and REPL.bufexists(self.buf)
    if bufobj then
        if cb then return cb(bufobj) end
        return bufobj
    end

    return cb(self)
end

function REPL.init(self, opts)
    opts = opts or {}
    local buflocal = opts.buffer
    local wslocal = opts.workspace
    local ftlocal = opts.filetype
    local buf = buflocal
    local ft
    local cmd, ws, conf

    buf = buffer.bufnr(buflocal or buffer.current())
    ft = buffer.filetype(buf)
    conf = filetype.attrib(ft, 'repl')

    if not conf then
        error('no config found for ' .. ft)
    end

    cmd, ws = filetype.command(ft, 'repl')(buffer.name(buf))
    local ftobj = REPL.ftexists(ft)
    local bufobj = REPL.bufexists(buf)
    local wsobj = ws and REPL.wsexists(ws)

    if ftlocal and ftobj then
        return ftobj
    elseif buflocal and bufobj then
        return bufobj
    elseif wslocal and wsobj then
        return wsobj
    end

    if ws and wslocal then
        self.workspace = ws
        self.type = 'workspace'
        cmd = 'cd ' .. self.workspace .. ' && ' .. cmd
    elseif buflocal then
        self.type = 'buffer'
    else
        self.type = 'filetype'
    end

    self.workspace = ws
    self.filetype = ft
    self.buf = buf

    return terminal.init(self, cmd, {})
end

function REPL.start(self)
    terminal.start(self)

    return REPL.if_type(self, {
        workspace = function (_)
            REPL.repls.workspace[self.workspace] = self
        end,
        filetype = function (_)
            REPL.repls.filetype[self.filetype] = self
        end,
        buffer = function (_)
            REPL.repls.buf[self.buf] = self
        end,
    })
end

function REPL.send_node_at_cursor(self)
    local function ft_ws_cb(_)
        return terminal.send_node_at_cursor(self, buffer.current())
    end

    return REPL.if_type(self, {
        filetype = ft_ws_cb,
        workspace = ft_ws_cb,
        buffer = function (_)
            return terminal.send_node_at_cursor(self, self.buf)
        end
    })
end

function REPL.send_current_line(self)
    local function ft_ws_cb(_)
        return terminal.send_current_line(self, buffer.current())
    end

    return REPL.if_type(self, {
        filetype = ft_ws_cb,
        workspace = ft_ws_cb,
        buffer = function (_)
            return terminal.send_current_line(self, self.buf)
        end
    })
end

function REPL.send_till_cursor(self)
    local function ft_ws_cb(_)
        return terminal.send_till_cursor(self, buffer.current())
    end

    return REPL.if_type(self, {
        filetype = ft_ws_cb,
        workspace = ft_ws_cb,
        buffer = function (_)
            return terminal.send_till_cursor(self, self.buf)
        end
    })
end

function REPL.send_range(self)
    local function ft_ws_cb(_)
        return terminal.send_range(self, buffer.current())
    end

    return REPL.if_type(self, {
        filetype = ft_ws_cb,
        workspace = ft_ws_cb,
        buffer = function (_)
            return terminal.send_range(self, self.buf)
        end
    })
end

function REPL.stop_all()
    for _, repls in pairs(REPL.repls) do
        for _, value in pairs(repls) do
            REPL.stop(value)
        end
    end

    REPL.repls = {buffer = {}, workspace = {}, filetype = {}}
end
