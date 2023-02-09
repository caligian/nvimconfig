local repl = REPL
local command = vim.api.nvim_create_user_command

local function get_repl(name) return repl.id[name] end

local function write(name, how)
	local r = get_repl(name)
	if r then
		if how == '.' then
			r:send_till_point()
		elseif how == 'l' then
			r:send_current_line()
		elseif how == 'b' then
			r:send_buffer()
		elseif how == 'i' then
			r:send(vim.fn.input('Send to REPL > '))
		elseif how == 'v' then
			r:send_visual_range()
		end
	end
end

local function write_shell_visual_range() write('sh', 'v') end

local function write_shell_line() write('sh', 'l') end

local function write_shell_buffer() write('sh', 'b') end

local function write_shell_till_point() write('sh', '.') end

local function write_shell_input() write('sh', 'i') end

local function write_line() write(vim.bo.filetype, 'l') end

local function write_buffer() write(vim.bo.filetype, 'b') end

local function write_till_point() write(vim.bo.filetype, '.') end

local function write_input() write(vim.bo.filetype, 'i') end

local function write_visual_range() write(vim.bo.filetype, 'v') end

local function ensure_repl(name)
	local r = get_repl(name)
	local cmd = repl.commands[name]

	if not cmd then
		V.nvim_err('No command defined for buffer filetype %s' .. name)
	elseif not r or not r.running then
		r = REPL(name)
		r:start()
	end
	return r
end

local function start_shell_repl()
	local name = 'sh'
	local r = ensure_repl(name)
	if r then r:split() end
end

local function stop_shell_repl()
	local name = 'sh'
	local r = ensure_repl(name)
	if r then r:stop() end
end

local function split_shell_repl()
	local name = 'sh'
	local split = 's'
	local r = ensure_repl(name)
	if r then r:split(split) end
end

local function vsplit_shell_repl()
	local name = 'sh'
	local split = 'v'
	local r = ensure_repl(name)
	if r then r:split(split) end
end

local function hide_shell_repl()
	local r = get_repl('sh')
	if r then r:hide() end
end

local function start_repl()
	local name = vim.bo.filetype
	if vim.bo.filetype == '' then
		V.nvim_err('Cannot start REPL')
	else
		local r = ensure_repl(name)
		if r then r:split() end
	end
end

local function stop_repl()
	local name = vim.bo.filetype
	local r = ensure_repl(name)
	if r then r:stop() end
end

local function split_repl()
	local name = vim.bo.filetype
	local split = 's'
	local r = ensure_repl(name)
	if r then r:split(split) end
end

local function vsplit_repl()
	local name = vim.bo.filetype
	local split = 'v'
	local r = ensure_repl(name)
	if r then r:split(split) end
end

local function hide_repl()
	local name = vim.bo.filetype
	local r = get_repl(name)
	if r then r:hide() end
end

command('ShellStart', start_shell_repl, {})
command('ShellSplit', split_shell_repl, {})
command('ShellVsplit', vsplit_shell_repl, {})
command('ShellStop', stop_shell_repl, {})
command('ShellHide', hide_shell_repl, {})
command('ShellSend', write_shell_input, {})
command('ShellSendBuffer', write_shell_buffer, {})
command('ShellSendLine', write_shell_line, {})
command('ShellSendTillpoint', write_shell_till_point, {})
command('ShellSendVisualRange', write_shell_visual_range, {})
command('REPLStart', start_repl, {})
command('REPLSplit', split_repl, {})
command('REPLStop', stop_repl, {})
command('REPLVsplit', vsplit_repl, {})
command('REPLHide', hide_repl, {})
command('REPLSend', write_input, {})
command('REPLSendBuffer', write_buffer, {})
command('REPLSendLine', write_line, {})
command('REPLSendTillpoint', write_till_point, {})
command('REPLSendVisualRange', write_visual_range, {})
command('REPLStopAll', REPL.stopall, {})
