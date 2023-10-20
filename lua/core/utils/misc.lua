-- Will not work with userdata
function whereis(bin, regex)
    local out = vim.fn.system("whereis " .. bin .. [[ | cut -d : -f 2- | sed -r "s/(^ *| *$)//mg"]])
    out = string.trim(out)
    out = string.split(out, " ")

    if dict.is_empty(out) then
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
function setglobal(vars)
    for var, value in pairs(vars) do
        if var:match "^!" then
            var = var:gsub("^!", "")
            _G[var] = value
        elseif _G[var] == nil then
            _G[var] = value
        end
        globals[var] = value
    end
end

function getglobal(var)
    if _G[var] then
        return _G[var]
    end
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

function joinpath(...)
    return table.concat({ ... }, "/")
end

function basename(s)
    s = vim.split(s, "/")
    return s[#s]
end

function req2path(s, is_file)
    local p = string.split(s, "[./]") or { s }
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
    if not s:match_any "^core" then
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
        return dict.merge(copy(builtin), _user)
    end

    return builtin
end

function optional(value, default)
    if value == nil then
        return default
    end

    return value
end

function pid_exists(pid)
    if not is_number(pid) then return false end

    local out = system("ps --pid " .. pid .. " | tail -n -1")
    out = array.map(out, string.trim)
    out = array.grep(out, function(x)
        return #x ~= 0
    end)

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
