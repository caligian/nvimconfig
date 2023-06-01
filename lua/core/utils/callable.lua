callable = class "callable"
callable.NotEnoughParams = exception "not enough parameters passed"
callable.InvalidNumberOfParams = exception "invalid number of parameters passed"
callable.InvalidParamSignature = exception "invalid parameter signature passed"

local function applyhook(before, after, f, ...)
  before = before or {}
  after = after or {}
  local args = { ... }
  local before_empty = array.isblank(before)
  local after_empty = array.isblank(after)
  local out = {}

  if not before_empty and not after_empty then return end

  if not before_empty then
    array.each(before, function(x) out = { x(unpack(args)) } end)
  end

  if not array.isblank(out) then
    out = { f(unpack(out)) }
  else
    out = { f(...) }
  end

  if not after_empty then
    array.each(after, function(x) out = { x(unpack(args)) } end)
  end

  return unpack(out)
end

local function create(opts, ...)
  local before, after, f, sig, n
  before = opts.before
  after = opts.after
  f = opts.f
  sig = opts.sig
  n = opts.n

  local args = { ... }
  local nargs = #args
  local nsig = sig and #sig or -1

  local invalidnumber = (nsig > nargs) or (nsig > 0 and nargs == 0)
  if invalidnumber then callable.InvalidNumberOfParams(args) end

  if sig then
    local all_msg = {}
    local all_msg_i = 1
    for i = 1, #sig do
      local ok, msg = is(sig[i])(args[i])
      if not ok and msg then
        all_msg[all_msg_i] = "param " .. i .. ": " .. msg
        all_msg_i = all_msg_i + 1
      end
    end

    if all_msg[1] then
      callable.InvalidParamSignature:throw { args = args, reason = all_msg }
    end
  end

  local ok = n and n ~= "*"
  if not ok then return applyhook(before, after, f, ...) end

  local notok = (n == "+" or n > 0) and nargs == 0
  if notok then callable.NotEnoughParams:throw(args) end

  notok = (n > 0 and nargs ~= n) or (n == 0 and nargs > 0)
  if notok then
    callable.InvalidNumberOfParams:throw {
      required = n,
      passed = nargs,
      args = args,
    }
  end

  local out = { f(...) }
  if not array.isblank(before) then
    array.each(before, function(x) out = x(unpack(out)) end)
  end

  return applyhook(before, after, f, ...)
end

function callable:init(f, opts)
  opts = opts or {}
  self.before = array.toarray(opts.before or {})
  self.after = array.toarray(opts.after or {})
  self.cache = opts.cache and {}
  self.n = opts.n
  self.sig = opts.sig
  self.f = f
end

function callable:call(...)
  return create({
    after = self.after,
    before = self.before,
    n = self.n,
    sig = self.sig,
    f = self.f,
  }, ...)
end

function callable:hookbefore(callback)
  validate {
    callback = {
      is { "callable", "class" },
      callback,
    },
  }

  array.append(self.before, callback)

  return callback
end

function callable:hookafter(callback)
  validate {
    callback = {
      is { "callable", "class" },
      callback,
    },
  }

  array.append(self.before, callback)

  return callback
end

function callable:copy(opts)
  return function(...) return create(opts or self) end
end

function callable:apply(args) return self:call(unpack(args)) end

function callable:partial(...)
  return partial(function(...) return self:call(...) end, ...)
end

function callable:rpartial(...)
  return rpartial(function(...) return self:call(...) end, ...)
end

function callable:decorate(callback)
  return decorate(function(...) return self:call(...) end, callback)
end

return callable
