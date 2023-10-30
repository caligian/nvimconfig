function to_stderr(...)
    for _, s in ipairs { ... } do
        vim.api.nvim_err_writeln(s)
    end
end

function exec(s, output)
    if output == nil then output = true end
    return vim.api.nvim_exec(s, output)
end

function system(...)
    return vim.fn.systemlist(...)
end

-- If multiple keys are supplied, the table is going to be assumed to be nested
user.logs = user.logs or {}
function req(require_string, do_assert)
    local ok, out = pcall(require, require_string)

    if ok then
        return out
    end

    append(user.logs, out)
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
    font = user and user.font and user.font.family
    height = user and user.font and user.font.height or '11'
	if not font then return end

    font = vim.o.guifont:match "^([^:]+)" or font
    height = vim.o.guifont:match "h([0-9]+)" or height

    return font, height
end

function log_pcall(f, ...)
    local ok, out = pcall(f, ...)
    if ok then
        return out
    else
        out = debug.traceback()
        user.logs[#user.logs + 1] = out
        logger:debug(out)
    end
end

function log_pcall_wrap(f)
    return function(...)
        return log_pcall(f, ...)
    end
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

function command(name, callback, opts)
    opts = opts or {}
    return vim.api.nvim_create_user_command(name, callback, opts or {})
end

del_command = vim.api.nvim_del_user_command

--- Only works for user and doom dirs
function reqloadfile(s)
    s = split(s, "%.")
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
        return _loadfile(path.join(os.getenv "HOME", ".nvim", unpack(s)))
    elseif s[1] then
        return _loadfile(path.join(vim.fn.stdpath "config", "lua", unpack(s)))
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

local function process_input(key, value)
    local out = {}
    local default, completion, cancelreturn, prompt, default, highlight, post, required
    required = value.required
    post = value.post
    prompt = (value.prompt or value[1] or key) .. ' > '
    default = value.default or value[2]
    cancelreturn = value.cancelreturn
    highlight = value.highlight
    completion = value[3] or value.completion
    local opts = {
        prompt = prompt,
        default = default,
        completion = completion,
        cancelreturn = cancelreturn,
        highlight = highlight,
    }
    local userint = vim.fn.input(opts):trim()

    if #userint == 0 then
        userint = false
    elseif userint:is_number() then
        userint = tonumber(userint)
    else
        userint = userint
    end

    if post then
        userint = post(userint)
    end

    if required then
        assert(userint, 'no input passed for non-optional key ' .. key)
    end

    out[key] = value

    return out
end

--- @tparam table[input_args] | input_args
function input(spec)
    if is_a.table(spec) then
        local res = {}

        for key, value in pairs(spec) do
            local out = process_input(key, value)
            merge(res, out)
        end

        return res
    else
        return process_input(1, unpack(spec))
    end
end

function whereis(bin, regex)
    local out = vim.fn.system("whereis " .. bin .. [[ | cut -d : -f 2- | sed -r "s/(^ *| *$)//mg"]])
    out = trim(out)
    out = split(out, " ")

    if is_empty(out) then
        return false
    end

    if regex then
        for _, value in ipairs(out) do
            if value:match(regex) then
                return value
            end
        end
    end

    return out[1]
end

-- For multiple patterns, OR matching will be used
-- If varname in [varname] = var is prefixed with '!' then it will be overwritten
function config_set(vars, attrib)
	if attrib then
		return merge(user[attrib], vars)
	end

	return merge(user, vars)
end

function config_get(attrib)
	return user[attrib]
end

function with_open(fname, mode, callback)
    local fh = io.open(fname, mode)
    local out = nil

    if fh then
        out = callback(fh)
        fh:close()
    end

    return out
end

function basename(s)
    s = vim.split(s, "/")
    return s[#s]
end

function req2path(s, is_file)
    local p = split(s, "[./]") or { s }
    local test
    user.user_dir = user.user_dir or path.join(os.getenv "HOME", ".nvim")
    user.dir = user.dir or vim.fn.stdpath "config"

    if p[1]:match "user" then
        test = path.join(user.user_dir, "lua", unpack(p))
    else
        test = path.join(user.dir, "lua", unpack(p))
    end

    local isdir = path.exists(test)
    local isfile = path.exists(test .. ".lua")

    if is_file and isfile then
        return test .. ".lua", "file"
    elseif isdir then
        return test, "dir"
    elseif isfile then
        return test .. ".lua", "file"
    end
end

function reqmodule(s)
    if not s:match "^core" then
        return
    end
    if s:match "^core%.utils" then
        return
    end

    local p = s:gsub("^core", "user")
    if not req2path(s) then
        return
    end

    local builtin, builtin_tp = req2path(s)
    local _user, user_tp = req2path(p)

    if not builtin then
        return
    elseif builtin_tp == "dir" and path.exists(builtin .. "/init.lua") then
        builtin = require(s)
    else
        builtin = require(s)
    end

    if user_tp == "dir" and path.exists(path.join(_user, "init.lua")) then
        _user = require(s)
    else
        _user = require(s)
    end

    if is_table(builtin) and is_table(_user) then
        return merge(copy(builtin), _user)
    end

    return builtin
end

function pid_exists(pid)
    if not is_number(pid) then return false end

    local out = system("ps --pid " .. pid .. " | tail -n -1")
    out = map(out, trim)
    out = filter(out, function(x) return #x ~= 0 end)

    if #out > 0 then
        if string.match(out[1], "error") then
            return false, out
        end

        return true
    end

    return false
end

function kill_pid(pid, signal)
    if not is_number(pid) then
        return false
    end

    local out = system('kill -s ' .. signal  .. ' ' .. pid)
    if #out == 0 then
        return false
    else
        return false
    end

    return true
end
