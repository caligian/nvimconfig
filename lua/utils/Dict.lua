require "utils.table"
require 'utils.dict'

class "Dict"

table.merge(Dict, dict)

function Dict:init(t)
  assert(type(t) == "table", "table expected, got " .. type(t))

  if is_class(t) then
    local name = t.class:get_name()
    if name ~= "Dict" then
      error("Dict|table expected, got " .. name)
    else
      self.value = t.value
    end
  else
    self.value = t
  end

  self:include(dict, "value")

  return self
end
