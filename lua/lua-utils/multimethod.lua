require "lua-utils.compare"

--- @class defmulti.spec
--- @field [1] any[] callable signatures
--- @field [2] function apply matched args to callable matched
--- @field cond? boolean return table as-is after matching signature
--- @field match? boolean return all matched keys in a new table for each pattern matched table
--- @field when? function[]|function params should match these conditions before matching the signature

--- Define a multimethod
--- @see case
--- @param specs defmulti.spec[]
--- @return any?
function defmulti(specs)
  return function(...)
    local args = list.fix { ... }

    for i = 1, #specs do
      local spec = specs[i]
      local key, value = unpack(specs[i])
      local opts = { cond = spec.cond, match = spec.match, absolute = true }
      local when = spec.when
      local ok = true

      assertisa.table(key)

      if when then
        if is_list(when) then
          return list.all(when, function(x)
            assertisa.callable(x)
            ---@diagnostic disable-next-line: param-type-mismatch
            ok = x(unpack(args))
          end)
        else
          assertisa.callable(x)
          ---@diagnostic disable-next-line: param-type-mismatch
          ok = x(unpack(args))
        end
      end

      if #key == #args and ok then
        ---@diagnostic disable-next-line: cast-local-type
        ok = case.match(args, key, opts)

        if ok then
          if opts.match then
            return value(ok)
          else
            if is_function(value) then
              return value(unpack(args))
            else
              return value
            end
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

-- local V = case.var
-- local mm = defmulti {
--   {
--     { { V "A", V "B" }, V(), V() },
--     function(n, o, p)
--       return { n, o, p }
--     end,
--     match = true,
--   },
-- }

-- mm({ 1, 2 }, -1, 2)
