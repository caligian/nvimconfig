require "utils.table"
require 'utils.array'

class "Array"

table.merge(Array, array)

function Array:init(t)
  assert(type(t) == "table", "table expected, got " .. type(t))

  if is_class(t) then
    local name = t.class:get_name()
    if name ~= "Array" then
      error("Array|table expected, got " .. name)
    else
      self.value = t.value 
    end
  else
    self.value = t
  end

  self:include(array_methods, 'value')

  return self
end
