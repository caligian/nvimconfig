require "core.utils.misc"

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

--- Only works for user and doom dirs
function reqloadfile(s)
    s = s:split "%."
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

--- @tparam array[array] array of input() args
function input(spec)
    local out = {}

    dict.each(spec, function(key, value)
        local name = key
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
            out[key] = false
        elseif userint:is_number() then
            out[key] = tonumber(userint)
        else
            out[key] = userint
        end

        if post then
            out[key] = post(out[key])
        end

        if required then
            assert(out[key], 'no input passed for non-optional key ' .. key)
        end
    end)

    return out
end

function whereis(bin, match)
    local fh = io.popen("whereis " .. bin .. " | cut -d : -f 2")
    local out = fh:read "*a"
    fh:close()

    out = out:trim()
    if #out == 0 then
        return
    end

    out = out:split " +"
    return array.grep(out, function(x)
        if not match then return not x:match "man.*%.gz$" and not path.isdir(x) end
        return x:match(match) and not x:match "man.*%.gz$" and not path.isdir(x)
    end)
end
