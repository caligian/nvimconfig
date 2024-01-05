require "lua-utils.compare"

function defmulti(specs)
  return function(...)
    local args = list.fix { ... }

    for i = 1, #specs do
      local spec = specs[i]
      local key, value = unpack(specs[i])
      local opts = { cond = spec.cond, match = spec.match }
      local when = spec.when
      local ok = true

      if not opts.cond and not opts.match then
        opts.absolute = true
      elseif opts.cond then
        opts.absolute = true
      end

      if when then
        if is_list(when) then
          return list.all(when, function(x)
            assertisa.callable(x)
            ok = x(unpack(args))
          end)
        else
          assertisa.callable(x)
          ok = x(unpack(args))
        end
      end

      if #key == #args and ok then
        ok = case.match(args, key, opts)

        if ok then
          if is_function(value) then
            return value(unpack(args))
          else
            return value
          end
        end
      end
    end

    if default then
      assertisa.callable(default)
      return default(...)
    end

    error("no signature matching args " .. dump { ... })
  end
end

--[[
local V = case.var
local mm = defmulti {
  { { "a" }, identity },
  {
    { a = identity, b = 2, c = { a = "f" } },
    function(literal)
      return "literal: ", literal
    end,
    cond = true,
  },
  {
    { { a = V(), d = V(is_string), c = 9 }, 1 },
    function(opts, a)
      return opts, a
    end,
    match = true
  },
  {
    { 1 },
    function(n)
      return n
    end,
  },
}
--]]
