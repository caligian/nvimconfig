function is(type_spec)
  type_spec = map(tolist(type_spec), function(i)
    return TYPES[i]
  end)

  return setmetatable({}, {
    __call = function(_, e)
      local invalid = {}
      for _, t in ipairs(type_spec) do
        if not is_a(e, t) then
          invalid[#invalid + 1] = t
        end
      end

      if #invalid == #type_spec then
        return false, string.format("expected %s, got %s", table.concat(invalid, "|"), tostring(e))
      end

      return true
    end,
    required = table.concat(type_spec, "|"),
  })
end

local function _validate(a, b)
  opts = opts or {}
  local depth = 1

  local function _compare(a, b)
    local nonexistent = a.__nonexistent == nil and true or a.__nonexistent
    local level_name = a.__table or tostring(a)
    a.__nonexistent = nil
    a.__table = nil
    local optional = {}
    local ks_a = keys(a)
    local ks_b = keys(b)

    ieach(ks_a, function(idx, k)
      k = tostring(k)
      local opt = k:match "^%?"
      local _k = k:gsub("^%?", "")
      if opt then
        optional[_k] = true
      end
      if _k:match "^[0-9]+$" then
        _k = tonumber(_k)
      end
      ks_a[idx] = _k
    end)

    ks_a = Set(ks_a)
    ks_b = Set(ks_b)
    local common = ks_a:intersection(ks_b)
    local missing = ks_a:difference(ks_b)
    local foreign = ks_b:difference(ks_a)

    missing:each(function(k)
      if optional[k] then
        return
      else
        error(string.format("%s: missing key: %s", level_name, dump(missing:values())))
      end
    end)

    if not nonexistent then
      assert(
        foreign:len() == 0,
        string.format("%s: unrequired keys: %s", level_name, dump(foreign:values()))
      )
    end

    each(common, function(key)
      local x, y

      -- Depth 1 is always the param to be checked
      if depth > 1 then
        level_name = level_name .. "." .. key
      end

      if optional[key] then
        x = a["?" .. key]
      else
        x = a[key]
      end
      y = b[key]

      local x_tp, y_tp = typeof(x), typeof(y)
      x_tp = tostring(x_tp)
      y_tp = tostring(y_tp)
      if is_a.t(x_tp) and is_a.t(y_tp) then
        assert(x_tp == y_tp, string.format("%s: expected %s, got %s", level_name, x_tp, y))
      elseif is_a.t(x) and is_a.t(y) then
        x.__table = key
        depth = depth + 1
        _compare(x, y)
      elseif is_a.f(x) then
        local ok, msg = x(y)
        if not ok then
          error(level_name .. ":" .. " " .. msg)
        end
      else
        x = TYPES[x] or x
        assert(is_a(y, x), string.format("%s: expected %s, got %s", level_name, x, y))
      end
    end)
  end

  _compare(a, b)
end

function validate(type_spec)
  teach(type_spec, function(display, spec)
    local tp, param = unpack(spec)
    if display:match "^%?" and param == nil then
      return
    end
    _validate({ __table = display, tp }, { param })
  end)
end
