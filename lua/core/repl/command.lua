local function check_filetype(ft)
	if not Lang.langs[ft] then
		return false
	end
	return ft
end

local function get_filetype(args)
	local ft = args.args
	if #ft == 0 then
		ft = vim.bo.filetype
		if #ft == 0 then
			local _, out = pcall(vim.api.nvim_buf_get_var, vim.fn.bufnr(), "_repl_filetype")
			ft = out or ""
		end
	end

	if not ft then
		return false
	else
		return ft
	end
end

local function wrap(f)
	return function(args)
		local ft = check_filetype(get_filetype(args))
		if ft then
			local r = REPL(ft)
			r:start()
			if f then
				return f(r)
			end
		end
	end
end

local function stop(args)
	local ft = check_filetype(get_filetype(args))
	if ft then
		local r = REPL(ft)
		r:stop()
	end
end

command(
	"StartREPL",
	wrap(function(r)
		r:float {dock=0.4}
	end),
	{ nargs = "?" }
)

command(
	"TerminateInputREPL",
	wrap(function(r)
		r:terminate_input()
	end),
	{ nargs = "?" }
)

command("StopREPL", stop, { nargs = "?" })

command(
	"SplitREPL",
	wrap(function(r)
		r:float {dock=0.4, reverse=true}
	end),
	{ nargs = "?" }
)

command(
	"VsplitREPL",
	wrap(function(r)
		r:float {panel=0.4, reverse=true}
	end),
	{ nargs = "?" }
)

command(
	"HideREPL",
	wrap(function(r)
		r:hide()
	end),
	{ nargs = "?" }
)

command(
	"SendREPL",
	wrap(function(r)
		r:send(vim.fn.input("Send string > "))
	end),
	{ nargs = "?" }
)

command(
	"SendLineREPL",
	wrap(function(r)
		r:send_current_line()
	end),
	{ nargs = "?" }
)

command(
	"SendBufferREPL",
	wrap(function(r)
		r:send_buffer()
	end),
	{ nargs = "?" }
)

command(
	"SendTillPointREPL",
	wrap(function(r)
		r:send_till_point()
	end),
	{ nargs = "?" }
)

command(
	"SendRangeREPL",
	wrap(function(r)
		r:send_visual_range()
	end),
	{ nargs = "?" }
)
