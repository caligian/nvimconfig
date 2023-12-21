function tostderr(...)
  for _, s in ipairs { ... } do
    vim.api.nvim_err_writeln(s)
  end
end

function nvimexec(s, as_string)
  local ok, res = pcall(vim.api.nvim_exec2, s, {output = true})
  if ok and res and res.output then
    return not as_string and split(res.output, "\n") or res.output
  end
end

function system(...)
  return vim.fn.systemlist(...)
end

function requirex(require_string, do_assert)
  local ok, out = pcall(require, require_string)

  if ok then
    return out
  end

  logger:debug(out)

  if do_assert then
    error(out)
  end
end

function glob(d, expr, nosuf, alllinks)
  nosuf = nosuf == nil and true or false
  return vim.fn.globpath(d, expr, nosuf, true, alllinks)
    or {}
end

function get_font()
  local font, height
  font = user and user.font and user.font.family
  height = user and user.font and user.font.height or "11"
  if not font then
    return
  end
  font = vim.o.guifont:match "^([^:]+)" or font
  height = vim.o.guifont:match "h([0-9]+)" or height

  return font, height
end

--- Only works for user and doom dirs
function loadfilex(s)
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
    return _loadfile(
      path.join(os.getenv "HOME", ".nvim", unpack(s))
    )
  elseif s[1] then
    return _loadfile(
      path.join(vim.fn.stdpath "config", "lua", unpack(s))
    )
  end
end

local function process_input(key, value)
  local out = {}
  local default, completion, cancelreturn, prompt, default, highlight, post, required
  required = value.required
  post = value.post
  prompt = (value.prompt or value[1] or key) .. " > "
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
  elseif userint:isnumber() then
    userint = tonumber(userint)
  else
    userint = userint
  end

  if post then
    userint = post(userint)
  end

  if required then
    assert(
      userint,
      "no input passed for non-optional key " .. key
    )
  end

  out[key] = value

  return out
end

--- @tparam table[input_args] | input_args
function input(spec)
  if isa.table(spec) then
    local res = {}

    for key, value in pairs(spec) do
      local out = process_input(key, value)
      dict.merge(res, out)
    end

    return res
  else
    return process_input(1, unpack(spec))
  end
end

function whereis(bin, regex)
  local out = vim.fn.system(
    "whereis "
      .. bin
      .. [[ | cut -d : -f 2- | sed -r "s/(^ *| *$)//mg"]]
  )
  out = trim(out)
  out = split(out, " ")

  if isempty(out) then
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

function basename(s)
  s = vim.split(s, "/")
  return s[#s]
end

function req2path(s, isfile)
  local p = split(s, "[./]") or { s }
  local test
  
  if p[1]:match "user" then
    test = path.join(user.paths.user, "lua", unpack(p))
  else
    test = path.join(user.paths.config, "lua", unpack(p))
  end

  local isdir = path.exists(test)
  isfile = path.exists(test .. ".lua")

  if isfile and isfile then
    return test .. ".lua", "file"
  elseif isdir then
    return test, "dir"
  elseif isfile then
    return test .. ".lua", "file"
  end
end

function requirem(s)
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
  elseif
    builtin_tp == "dir"
    and path.exists(builtin .. "/init.lua")
  then
    builtin = requirex(s)
  else
    builtin = requirex(s)
  end

  if
    user_tp == "dir"
    and path.exists(path.join(_user, "init.lua"))
  then
    _user = requirex(s)
  else
    _user = requirex(s)
  end

  if istable(builtin) and istable(_user) then
    return dict.merge(copy(builtin), _user)
  end

  return builtin
end

function pid_exists(pid)
  if not isnumber(pid) then
    return false
  end

  local out = system("ps --pid " .. pid .. " | tail -n -1")
  out = list.map(out, trim)
  out = list.filter(out, function(x)
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
  if not isnumber(pid) then
    return false
  end

  signal = signal or ""
  local out = system("kill -s " .. signal .. " " .. pid)
  if #out == 0 then
    return false
  else
    return false
  end

  return true
end

function nvimcommand(name, callback, opts)
  opts = copy(opts or {})
  local use = vim.api.nvim_create_user_command
  local buf

  if opts.buffer then
    buf = opts.buffer == true and buffer.current() or opts.buffer
    use = vim.api.nvim_buf_create_user_command
  end

  opts.buffer = nil
  if buf then
    return use(buf, name, callback, opts)
  end

  return use(name, callback, opts)
end
