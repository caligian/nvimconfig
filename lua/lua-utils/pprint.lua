--- Object inspection utilities
local inspect = require 'inspect'
local pprint = {}

--- Stringify object
-- @param x object
-- @return string
function pprint.dump(x)
  return inspect(x)
end

--- Stringify and print object
-- @param x object
function pprint.pp(x)
  print(inspect(x))
end

--- sprintf with stringification
-- @param fmt string.format compatible format
-- @param ... placeholder variables
-- @return string
function pprint.sprintf(fmt, ...)
  local args = {...}
  for i = 1, #args do
    args[i] = type(args[i]) ~= 'string' and inspect(args[i]) or args[i]
  end

  return string.format(fmt, unpack(args)) 
end

--- printf with stringification
-- @param fmt string.format compatible format
-- @param ... placeholder variables
function pprint.printf(fmt, ...)
  print(pprint.sprint(fmt, ...))
end

printf = pprint.printf
sprintf = pprint.sprintf
pp = pprint.pp
dump = pprint.dump

return pprint
