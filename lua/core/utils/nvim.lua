require("core.utils.misc")

function nvimerr(...)
	for _, s in ipairs({ ... }) do
		vim.api.nvim_err_writeln(s)
	end
end

function nvimexec(s, output)
	output = output == nil and true or output
	return vim.api.nvim_exec(s, output)
end

-- If multiple dict.keys are supplied, the table is going to be assumed to be nested
user.logs = user.logs or {}
function req(require_string, do_assert)
	local ok, out = pcall(require, require_string)
	if ok then
		return out
	end
	array.append(user.logs, out)
	logger:debug(out)

	if do_assert then
		error(out)
	end
end

function glob(d, expr, nosuf, alllinks)
	nosuf = nosuf == nil and true or false
	return vim.fn.globpath(d, expr, nosuf, true, alllinks) or {}
end

function get_font()
	local font, height
	font = user and user.font.family
	height = user and user.font.height
	font = vim.o.guifont:match("^([^:]+)") or font
	height = vim.o.guifont:match("h([0-9]+)") or height

	return font, height
end

function log_pcall(f, ...)
	local ok, out = pcall(f, ...)
	if ok then
		return out
	else
		out = debug.traceback()
		logger:debug(out)
	end
end

function log_pcall_wrap(f)
	return function(...)
		return log_pcall(f, ...)
	end
end

function throw_error(desc)
	error(dump(desc))
end

function try_require(s, success, failure)
	local M = require(s)
	if M and success then
		return success(M)
	elseif not M and failure then
		return failure(M)
	end
	return M
end

function copy(obj, deep)
	if type(obj) ~= "table" then
		return obj
	elseif deep then
		return vim.deepcopy(obj)
	end

	local out = {}
	for key, value in pairs(obj) do
		out[key] = value
	end

	return out
end

function command(name, callback, opts)
	opts = opts or {}
	return vim.api.nvim_create_user_command(name, callback, opts or {})
end

del_command = vim.api.nvim_del_user_command

-- form: {var, <input-option> ...}
function input(...)
	local args = { ... }
	local out = {}

	for _, form in ipairs(args) do
		assert(is_a.table(form) and #form >= 1, "form: {var, [rest vim.fn.input args]}")

		local name = form[1]
		local s = vim.fn.input((form[2] or name) .. " % ", unpack(array.rest(array.rest(form))))

		if #s == 0 then
			pp("\nexpected string for param " .. name)
			return
		end

		out[name] = s
	end

	return out
end

--- Only works for user and doom dirs
function reqloadfile(s)
	s = s:split("%.")
	local fname

	local function _loadfile(p)
		local loaded
		if path.isdir(p) then
			loaded = loadfile(path.join(p, "init.lua"))
		else
			p = p .. ".lua"
			loaded = loadfile(p)
		end

		return loaded and loaded()
	end

	if s[1] == "user" then
		return _loadfile(path.join(os.getenv("HOME"), ".nvim", unpack(s)))
	elseif s[1] then
		return _loadfile(path.join(vim.fn.stdpath("config"), "lua", unpack(s)))
	end
end

function req(s)
	local p, tp = req2path(s)
	if not p then
		return
	elseif tp == "dir" and path.exists(p .. "/init.lua") then
		require(s)
	else
		require(s)
	end
end

function input(spec)
	local out = {}

	array.each(spec, function(value)
		local key = value[1]

		validate[key]({
			opt_validate = "callable",
			opt_prompt = "string",
			opt_completion = "string",
			opt_post = "callable",
		}, value)

		local check = value.validate
		local prompt = value.prompt or key
		local default = value.default
		local required = value.required
		local post = value.post
			or function(x)
				if x:match("^[0-9]+$") then
					return tonumber(x)
				end
				return x
			end
		prompt = prompt .. " > "

		local userint
		if not default then
			userint = vim.fn.input(prompt)
		else
			userint = vim.fn.input(prompt)
		end

		userint = #userint == 0 and false or stringtrim(userint)

		if #userint == 0 then
			userint = false
		end

		if not userint and default then
			userint = default
		end

		if required == nil then
			required = true
		end

		if required and not userint then
			error("invalid input passed :" .. dump(value))
		end

		if check then
			local ok, msg = check(userint)
			if not ok then
				error("invalid input passed :" .. msg)
			end
		end

		if post then
			userint = post(userint)
		end

		out[key] = userint
	end)

	return out
end
