local function wrap(f)
	return function(args)
		local ft = args.args
		ft = #args.args == 0 and vim.bo.filetype or args.args
		local r = REPL(ft)
		r:start()
		if f then
			return f(r)
		end
	end
end

local function start(r)
	r:split("s")
end

V.command("StartREPL", wrap(start), { nargs = "?" })
V.command(
	"StopREPL",
	wrap(function(r)
		r:stop()
	end),
	{ nargs = "?" }
)
V.command(
	"SplitREPL",
	wrap(function(r)
		r:split("s")
	end),
	{ nargs = "?" }
)
V.command(
	"VsplitREPL",
	wrap(function(r)
		r:split("v")
	end),
	{ nargs = "?" }
)
V.command(
	"HideREPL",
	wrap(function(r)
		r:hide()
	end),
	{ nargs = "?" }
)
V.command(
	"SendREPL",
	wrap(function(r)
		r:send(vim.fn.input("Send string > "))
	end),
	{ nargs = "?" }
)
V.command(
	"SendLineREPL",
	wrap(function(r)
		r:send_current_line()
	end),
	{ nargs = "?" }
)
V.command(
	"SendBufferREPL",
	wrap(function(r)
		r:send_buffer()
	end),
	{ nargs = "?" }
)
V.command(
	"SendTillPointREPL",
	wrap(function(r)
		r:send_till_point()
	end),
	{ nargs = "?" }
)
V.command(
	"SendRangeREPL",
	wrap(function(r)
		r:send_visual_range()
	end),
	{ nargs = "?" }
)
