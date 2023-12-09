require("core.utils.terminal")
require("core.utils.kbd")
require("core.utils.filetype")

REPL = REPL
	or struct("REPL", {
		"pid",
		"id",
		"cmd",
		"opts",
		"load_file",
		"on_input",
		"buffer",
		"type",
		"workspace",
		"filetype",
		"buf",
		"shell",
	})

dict.merge(REPL, terminal)

REPL.terminals = nil
REPL.repls = REPL.repls or { buffer = {}, workspace = {}, filetype = {} }
REPL.wslookup = REPL.wslookup or {}

local function buf2ws(buf)
	buf = buffer.bufnr(buf or buffer.current())
	local ws = REPL.wslookup[buf]

	if ws and path.exists(ws) then
		return ws
	end

	ws = filetype.workspace(buffer.name(buf))

	if not ws then
		return
	end

	REPL.wslookup[ws] = ws
	REPL.wslookup[ws] = buf

	return ws
end

function REPL.exists(what, arg, callback, orelse)
	if what == "b" then
		what = "buffer"
	elseif what == "w" then
		what = "workspace"
	else
		what = "filetype"
		arg = isnumber(arg) and buffer.filetype(arg) or arg
	end

	local check_in = REPL.repls[what]
	assert(istable(check_in), "expected any of b, w, f")

	if what == "workspace" then
		arg = buf2ws(buf)
	end

	local exists = check_in[arg]

	if not exists or not REPL.isrunning(exists) then
		if orelse then
			return orelse()
		end
		return
	elseif callback then
		return callback(exists)
	end

	return exists
end

function REPL.bufexists(buf, callback, orelse)
	return REPL.exists("b", buf, callback, orelse)
end

function REPL.ftexists(ft, callback, orelse)
	return REPL.exists("f", ft, callback, orelse)
end

function REPL.wsexists(ws, callback, orelse)
	return REPL.exists("w", ws, callback, orelse)
end

function REPL.if_type(self, callbacks)
	local tp = self.type
	local isft = tp == "filetype"
	local isbuf = tp == "buffer"
	local isws = tp == "workspace"
	callbacks = callbacks or {}
	local cb = callbacks[tp]

	local wsobj = isws and REPL.wsexists(self.workspace)
	if wsobj then
		if cb then
			return cb(wsobj)
		end
		return wsobj
	end

	local ftobj = isft and REPL.ftexists(self.filetype)
	if ftobj then
		if cb then
			return cb(ftobj)
		end
		return ftobj
	end

	local bufobj = isbuf and REPL.bufexists(self.buf)
	if bufobj then
		if cb then
			return cb(bufobj)
		end
		return bufobj
	end

	return cb(self)
end

local function shell_init(self)
	if REPL.shell and terminal.isrunning(REPL.shell) then
		return REPL.shell
	end

	REPL.shell = terminal.init(self, "bash")
	return REPL.shell
end

function REPL.init(self, opts)
	opts = opts or {}
	local boolnum = union("boolean", "number")
	local buf, wslocal, ftlocal, buflocal, bufname, ft, cmd, ws, conf
	wslocal = opts.workspace
	ftlocal = opts.filetype
	buflocal = opts.buffer
	local shell = opts.shell

	if shell then
		return shell_init(self)
	elseif isnumber(wslocal) then
		buf = wslocal
		wslocal = true
	elseif isnumber(ftlocal) then
		buf = ftlocal
		ftlocal = true
	elseif isnumber(buflocal) then
		buf = buflocal
		buflocal = true
	elseif wslocal == true then
		buf = buffer.current()
		wslocal = true
	elseif buflocal == true then
		buf = buffer.current()
		buflocal = true
	elseif ftlocal == true then
		buf = buffer.current()
		ftlocal = true
  else
		buf = buflocal or buffer.current()
		buflocal = true
	end

	bufname = buffer.name(buf)
	ft = buffer.filetype(buf)

	conf = filetype.attrib(ft, "repl")
	if not conf then
		error("no config found for " .. ft)
	end

	cmd, ws = filetype.command(ft, "repl")
	if not cmd then
		error("no command for filetype " .. ft)
	end

	cmd = cmd(bufname)
	local ftobj, bufobj, wsobj

	if wslocal then
		ws = ws or buf2ws(buf)
		wsobj = REPL.wsexists(ws)

		if wsobj then
			return wsobj
		elseif not ws then
			error(path.basename(bufname) .. ": not in workspace")
		end

		self.workspace = ws
		self.type = "workspace"
	elseif ftlocal then
		ftobj = REPL.ftexists(ft)
		if ftobj then
			return ftobj
		end
		self.filetype = ft
		self.type = "filetype"
	elseif buf then
		bufobj = REPL.bufexists(buf)
		if bufobj then
			return bufobj
		end
		self.type = "buffer"
	end

	self.buf = buf

	return terminal.init(self, cmd, { on_input = conf.on_input, load_file = conf.load_file })
end

function REPL.start(self)
	terminal.start(self)

	return REPL.if_type(self, {
		workspace = function(_)
			REPL.repls.workspace[self.workspace] = self
		end,
		filetype = function(_)
			REPL.repls.filetype[self.filetype] = self
		end,
		buffer = function(_)
			REPL.repls.buffer[self.buf] = self
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
		buffer = function(_)
			return terminal.send_node_at_cursor(self, self.buf)
		end,
	})
end

function REPL.send_current_line(self)
	local function ft_ws_cb(_)
		return terminal.send_current_line(self, buffer.current())
	end

	return REPL.if_type(self, {
		filetype = ft_ws_cb,
		workspace = ft_ws_cb,
		buffer = function(_)
			return terminal.send_current_line(self, self.buf)
		end,
	})
end

function REPL.send_till_cursor(self)
	local function ft_ws_cb(_)
		return terminal.send_till_cursor(self, buffer.current())
	end

	return REPL.if_type(self, {
		filetype = ft_ws_cb,
		workspace = ft_ws_cb,
		buffer = function(_)
			return terminal.send_till_cursor(self, self.buf)
		end,
	})
end

function REPL.send_range(self)
	local function ft_ws_cb(_)
		return terminal.send_range(self, buffer.current())
	end

	return REPL.if_type(self, {
		filetype = ft_ws_cb,
		workspace = ft_ws_cb,
		buffer = function(_)
			return terminal.send_range(self, self.buf)
		end,
	})
end

function REPL.stop_all()
	for _, repls in pairs(REPL.repls) do
		for _, value in pairs(repls) do
			if value then
				REPL.stop(value)
			end
		end
	end

	if REPL.shell then
		terminal.stop(REPL.shell)
	end

	REPL.repls = { buffer = {}, workspace = {}, filetype = {} }
end

function REPL.start_and_split(opts)
	opts = copy(opts)
	local sp = opts.split or "split"
	opts.split = nil
	local x = REPL(opts)

	if not x then
		return
	end

	REPL.start(x)
	REPL[sp](x, sp)
end

function REPL.bufstop(bufnr, what)
	if isstring(bufnr) then
		what = bufnr
		bufnr = nil
	end

	what = what or "b"

	REPL.exists(what, buffer.bufnr(bufnr), function(x)
		REPL.stop(x)
	end)
end

local exclude = {
	init = true,
	terminals = true,
	repls = true,
	wslookup = true,
	exists = true,
	bufexists = true,
	ftexists = true,
	wsexists = true,
	if_type = true,
	stop_all = true,
	bufstop = true,
	start_and_split = true,
}

local function create_shell_proxy()
	REPL.sh = setmetatable({
		start_and_split = function(direction)
			direction = direction or "split"
			local sh = shell_init(REPL({ shell = true }))
			terminal.start(sh)
			return terminal.split(sh, direction)
		end,
	}, {
		__call = function(self)
			return shell_init(self)
		end,
		__index = function(self, key)
			assertunless(exclude[key], "cannot use method " .. key)

			local f = terminal[key]
			assert(terminal[key], "invalid method " .. key)

			rawset(self, key, function()
				local f = terminal[key]
				local x = shell_init(REPL({ shell = true }))
				terminal.start(x)

				return f(x)
			end)

			return self[key]
		end,
	})
end

local function create_proxy(what)
	REPL[what] = setmetatable({
		bufstop = function(bufnr)
			bufnr = bufnr or buffer.bufnr()
			return REPL.bufstop(bufnr, what:sub(1, 1))
		end,
		start_and_split = function(direction)
			direction = direction or "split"
			local bufnr = buffer.bufnr()
			return REPL.start_and_split({ [what] = bufnr, split = direction })
		end,
	}, {
		__call = function(self, bufnr)
			bufnr = bufnr or buffer.bufnr()
			return REPL({ [what] = buffer.bufnr(bufnr) })
		end,
		__index = function(self, key)
			assertunless(exclude[key], "cannot use method " .. key)

			local f = REPL[key]
			assert(REPL[key], "invalid method " .. key)

			return function(arg, ...)
				arg = buffer.bufnr(arg or buffer.current())

				if key == "stop" then
					return REPL.stop(REPL({ [what] = arg }))
				end

				local x = REPL({ [what] = arg })
				REPL.start(x)

				local method = what:match("filetype") and "ft"
					or what:match("buffer") and "buf"
					or what:match("workspace") and "ws"

				method = method .. "exists"
				method = REPL[method]

				return method(arg, function(obj, ...)
					return f(obj, ...)
				end)
			end
		end,
	})
end

create_proxy("filetype")
create_proxy("buffer")
create_proxy("workspace")
create_shell_proxy()

function REPL.map(mode, key, fun, sp)
	local wsfun, buffun, ftfun, shfun
	local wsdesc, bufdesc, ftdesc

	mode = mode or "n"
	wsfun = REPL.workspace[fun]
	buffun = REPL.buffer[fun]
	ftfun = REPL.filetype[fun]
	shfun = REPL.sh[fun]

	if fun == "start_and_split" and key == "v" then
		sp = sp or "split"
		wsfun = partial(wsfun, sp)
		buffun = partial(buffun, sp)
		ftfun = partial(ftfun, sp)
		shfun = partial(shfun, sp)
		wsdesc = "workspace_" .. "v" .. fun
		ftdesc = "filetype_" .. "v" .. fun
		bufdesc = "buffer_" .. "v" .. fun
		shdesc = "sh_" .. "v" .. fun
	else
		wsdesc = "workspace_" .. fun
		ftdesc = "filetype_" .. fun
		bufdesc = "buffer_" .. fun
		shdesc = "sh_" .. fun
	end

	local opts = { noremap = true, leader = true, prefix = "r" }
	kbd.map(mode, key:upper(), ftfun, dict.merge({ desc = ftdesc }, opts))
	kbd.map(mode, key, buffun, dict.merge({ desc = bufdesc }, opts))
	kbd.map(mode, key, wsfun, { noremap = true, localleader = true, prefix = "r", desc = wsdesc })

	if key == "r" then
		key = "x"
	end

	kbd.map(mode, key, shfun, { noremap = true, leader = true, prefix = "x", desc = shdesc })
end
