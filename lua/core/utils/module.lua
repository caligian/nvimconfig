function statemodule()
  local mod = {STATE={}}
  local state = mod.STATE

  return setmetatable(mod, {
    __newindex = function(self, key, value)
      if not state[key] then 
        state[key] = value
        return 
      end

      local v = state[key]
      if not v then
        state[key] = value
      elseif is_a.table(v) and is_a.table(value) then
        state[key] = dict.merge(v, value)
      else
        state[key] = value
      end
    end,
    __index = function (self, key)
      return state[key]
    end
  })
end
