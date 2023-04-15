local mt = {type='error'}
Error = setmetatable({}, mt)
Error.__index = Error

local function get_repr(self, obj, reason)
  local traceback = vim.split(
    debug.traceback('', 3), 
    "\n"
  )

  table.shift(traceback, 2)

  if traceback then
    for i = 1, #traceback do
      traceback[i] = "  " .. vim.trim(traceback[i])
    end

  end

  return setmetatable({
    reason = self.reason or reason,
    obj = obj,
    traceback = traceback,
    name = self.name,
  }, {
    __tostring = function (self) 
      local fmt = [[

[error]
%s

[reason]
%s

[traceback]
%s

[object]
%s
]]

      local traceback_s = table.concat(self.traceback, "\n")
      local obj_s 

      if is_table(obj) and mtget(obj, '__tostring') then
        obj_s = tostring(obj)
      else
        obj_s = dump(obj)
      end

      return sprintf(fmt, self.name, self.reason, traceback_s, obj_s)
    end
  })
end

function Error:throw(obj, reason)
  error(get_repr(self, obj, reason))
end

function Error:__tostring()
  return dump(get_repr(self))
end

function Error:is_a(x)
  return mtget(x, 'type') == 'error'
end

function mt:__call(name, reason)
  local self = setmetatable({}, Error)
  self.name = name
  self.reason = reason

  return self
end

--- 
mt = {type='exception'}
Exception = setmetatable({errors = {}}, mt)
Exception.__index = Exception

function Exception:is_a(x)
  return mtget(x, 'type') == 'error'
end

function Exception:__tostring()
  local out = {}
  for name, err_obj in pairs(self.errors) do
    out[name] = tostring(err_obj)
  end

  return out
end

function Exception:__newindex(err_name, reason)
  local err = Error(err_name, reason)
  self.errors[err_name] = err

  return err
end

function Exception:__index(k)
  if self.errors[k] then
    return self.errors[k]
  end
end

function Exception:add(err_name, reason)
  return self:__newindex(err_name, reason)
end

function Exception:remove(err_name)
  local obj = self.errors[err_name]
  self.errors[err_name] = nil

  return obj
end

function Exception:throw(err_name, obj, reason)
  self.errors[err_name]:throw(obj, reason)
end

function Exception:set(err_spec)
  for err_name, reason in pairs(err_spec) do
    self:add(err_name, reason)
  end

  return self.errors
end

function mt:__call(name)
  return setmetatable({name=name, errors={}}, Exception)
end
