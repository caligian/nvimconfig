require "utils.errors"

function module(methods)
  local mod = {}
  for key, value in pairs(methods or {}) do
    mod[key] = value
  end

  return mod
end

local exception = Exception "StateModuleException"
exception.not_a_class = "class expected"

function state_module(cls, methods)
  exception.not_a_table:throw_unless(is_table(cls), cls)
  TypeException.not_a_table:throw_unless(is_table(methods), methods)

  local mod = module(methods or {})
  mod.objects = {}
  local state = mod.objects

  function mod.get_state()
    return mod.objects
  end

  function mod.get(obj_name)
    return state[obj_name]
  end

  function mod.add(obj_name, ...)
    state[obj_name] = cls(...)
    return state[obj_name]
  end

  function mod.create(obj_name, ...)
    if not state[obj_name] then
      mod.add(obj_name, ...)
    end
    return state[obj_name]
  end

  function mod.remove(obj_name, ...)
    local args = { ... }

    if #args == 0 then
      state[obj_name] = nil
    else
      local obj = mod.get(obj_name)
      if not obj then
        return
      elseif obj.remove then
        return obj:remove(...)
      end

      return obj
    end
  end

  function mod.delete(obj_name)
    state[obj_name] = nil
  end

  local add, remove, create = mod.add, mod.remove, mod.create

  function mod.init_remove(before, after)
    if before and not after then
      after = before
      before = nil
    end

    function mod.remove(...)
      local args = { ... }
      local out = args

      if before then
        out = { before(unpack(args)) }
      end

      if after then
        out = { after(remove(unpack(out))) }
      else
        out = remove(unpack(out))
      end

      return out
    end
  end

  function mod.init_create(before, after)
    if before and not after then
      after = before
      before = nil
    end

    function mod.create(...)
      local args = { ... }
      local out = args

      if before then
        out = { before(unpack(args)) }
      end

      if after then
        out = { after(create(unpack(out))) }
      else
        out = create(unpack(out))
      end

      return out
    end
  end

  function mod.init_add(before, after)
    if before and not after then
      after = before
      before = nil
    end

    function mod.add(...)
      local args = { ... }
      local out = args

      if before then
        out = { before(unpack(args)) }
      end

      if after then
        out = { after(add(unpack(out))) }
      else
        out = add(unpack(out))
      end

      return out
    end
  end

  return mod
end
