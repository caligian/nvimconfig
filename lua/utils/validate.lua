function is(type_spec)
  type_spec = table.map(
    table.tolist(type_spec),
    function(i) return TYPES[i] end
  )

  return setmetatable({}, {
    __call = function(_, e)
      local invalid = {}
      for _, t in ipairs(type_spec) do
        if not is_a(e, t) then invalid[#invalid + 1] = t end
      end

      if #invalid == #type_spec then
        return false,
          string.format(
            "expected %s, got %s",
            table.concat(invalid, "|"),
            tostring(typeof(e))
          )
      end

      return true
    end,
    required = table.concat(type_spec, "|"),
  })
end

local function _validate(a, b)
  opts = opts or {}

  local function _compare(a, b)
    local nonexistent = a.__nonexistent == nil and true or a.__nonexistent
    local level_name = a.__table or tostring(a)
    a.__nonexistent = nil
    a.__table = nil
    local optional = {}
    local ks_a = table.keys(a)
    local ks_b = table.keys(b)

    table.ieach(ks_a, function(idx, k)
      k = tostring(k)
      local opt = k:match "^%?"
      local _k = k:gsub("^%?", "")
      if opt then optional[_k] = true end
      if _k:match "^[0-9]+$" then _k = tonumber(_k) end
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
        error(
          string.format(
            "%s: missing key: %s",
            level_name,
            dump(missing:values())
          )
        )
      end
    end)

    if not nonexistent then
      assert(
        foreign:len() == 0,
        string.format(
          "%s: unrequired table.keys: %s",
          level_name,
          dump(foreign:values())
        )
      )
    end

    table.each(common:values(), function(key)
      display = key:gsub("^%?", "")

      local tp, param = a[display], b[display]
      if optional[display] and param == nil then return end

      if is_callable(tp) then
        local ok, msg = tp(param)
        if not ok then
          error(display .. ": " .. msg or "callable failed " .. tostring(param))
        end
      elseif type(tp) == "table" then
        if not is_a.t(param) then
          error(display .. ": expected table, got " .. typeof(param))
        end
        if is_class(tp) then
          if not is_a(param, tp) then
            error(sprintf("%s: expected %s, got ", display, tp, typeof(param)))
          end
        else
          tp.__table = display
          _compare(tp, param)
        end
      elseif is_a.s(tp) then
        if not is_a(param, tp) then
          tp = TYPES[tp]
          error(display .. ": expected " .. tp .. ", got " .. typeof(param))
        end
      else
        local m, n = typeof(tp), typeof(param)
        assert(m == n, sprintf("%s: expected %s, got %s", display, m, n))
      end
    end)
  end

  _compare(a, b)
end

function validate(type_spec)
  table.teach(type_spec, function(display, spec)
    local tp, param = unpack(spec)
    if display:match "^%?" and param == nil then return end
    display = display:gsub("^%?", "")

    if is_callable(tp) then
      local ok, msg = tp(param)
      if not ok then
        error(display .. ": " .. msg or "callable failed " .. param)
      end
    elseif type(tp) == "table" then
      if not is_a.t(param) then
        error(display .. ": expected table, got " .. param)
      end
      if is_class(tp) then
        assert(
          is_a(param, tp),
          sprintf("%s: expected %s, got ", display, tp, param)
        )
      else
        tp.__table = display
        _validate(tp, param)
      end
    elseif is_a.s(tp) then
      assert(
        is_a(param, tp),
        display .. ": expected " .. tp .. ", got " .. typeof(param)
      )
    else
      local a, b = typeof(tp), typeof(param)
      assert(a == b, sprintf("%s: expected %s, got %s", display, a, b))
    end
  end)
end
