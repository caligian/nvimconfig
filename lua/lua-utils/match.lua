require "lua-utils.table"

local function is_var(obj)
  return typeof(obj) == "case.variable"
end

local function tmatch(obj, spec, opts)
  opts = opts or {}
  local pre_a = opts.pre_a
  local pre_b = opts.pre_b
  local absolute = opts.absolute
  local cond = opts.cond
  local match = opts.match
  local same_size = opts.same_size
  local eq = opts.eq

  if cond or match then
    absolute = true
  end

  if same_size and size(obj) ~= size(spec) then
    return false
  end

  local vars = match and {}
  local Vars = vars
  local Obj = obj
  local Spec = spec

  local queue = {
    add = function(self, item)
      self[#self + 1] = item
    end,
    pop = function(self)
      local item = self[#self]
      self[#self] = nil

      return item
    end,
  }

  local state = not absolute and {}
  local State = state

  while Obj and Spec do
    if same_size and size(Obj) ~= size(Spec) then
      if absolute then
        return false
      else
        return State
      end
    end

    for i, validator in pairs(Spec) do
      local key = i
      local obj_value
      local optional

      if is_string(i) or is_number(i) then
        key, optional = tostring(i):gsub("(^opt_|%?$)", "")
        key = tonumber(key) or key
        optional = optional > 0
        obj_value = Obj[key]
      else
        obj_value = Obj[i]
      end

      if not is_nil(obj_value) and pre_a then
        obj_value = pre_a(obj_value)
      end

      if pre_b then
        validator = pre_b(validator)
      end

      if is_nil(obj_value) then
        if not optional then
          if absolute then
            return false
          else
            State[key] = false
          end
        end
      elseif cond or match then
        if is_function(validator) then
          if not validator(obj_value) then
            return false
          end
        elseif is_var(validator) then
          assert(match, "cannot use case.variables without .match = true")

          if not validator.name then
            validator.name = key
          end

          local test = validator.test

          if test ~= nil then
            assertisa[union("function", "table")](test)
          end

          if test == nil then
            if match then
              Vars[validator.name] = obj_value
            else
              State[key] = true
            end
          elseif is_function(test) then
            local ok = test(obj_value)
            if not ok then
              return false
            else
              Vars[validator.name] = obj_value
            end
          elseif not is_table(obj_value) then
            return false
          else
            Vars[validator.name] = {}
            queue:add { obj_value, test, vars = Vars[key] }
          end
        elseif eq and not eq(obj_value, validator) then
          return false
        elseif obj_value ~= validator then
          return false
        end
      elseif is_table(validator) then
        if not is_table(obj_value) then
          if absolute then
            return false
          else
            State[key] = false
          end
        else
          State[key] = {}
          ---@diagnostic disable-next-line: need-check-nil
          queue:add { obj_value, validator, state = State[key] }
        end
      elseif eq then
        if not eq(obj_value, validator) then
          if absolute then
            return false
          else
            State[key] = false
          end
        elseif not absolute then
          State[key] = true
        end
      elseif obj_value ~= validator then
        if absolute then
          return false
        else
          State[key] = false
        end
      elseif not absolute then
        State[key] = true
      end
    end

    local next_items = queue:pop()
    if next_items then
      Obj, Spec = next_items[1], next_items[2]
      Vars = next_items.vars
      State = next_items.state
    else
      Obj = nil
      Spec = nil
    end
  end

  if match then
    if size(vars) == 0 then
      return obj
    end
    return vars
  elseif cond then
    return obj
  else
    return state
  end
end

local V = case.var
local spec = {
  V(is_number),
  V(is_number),
  V(is_number),
  V { V("A", is_number), V "B", 7 },
}
pp(tmatch({ 1, 2, 3, { 5, 6, 7 } }, spec, { match = true }))
