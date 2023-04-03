require 'utils.Class'
require 'utils.table'

class 'Table'

local include = {}
for key, value in pairs(table) do
  if key ~= 'range' then
    include[key] = value
  end
end

Table:include(include, 'value')

function Table:init(t)
  assert(type(t) == 'table', 'table expected, got ' .. tostring(t))

  if t.get_name and t:get_name() == 'Table' then
    return t
  end

  self.value = t 
end
