require "utils.table"

class "Dict"

dict = {
  each = table.teach,
  map = table.tmap,
  filter = table.tfilter,
  grep = table.tgrep,
  get = table.get,
  contains = table.contains,
  merge = table.merge,
  lmerge = table.lmerge,
  update = table.update,
  compare = table.compare,
  index = table.index,
  isblank = table.isblank,
  keys = table.keys,
  values = table.values,
  copy = vim.deepcopy,
  items = table.items,
}

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
