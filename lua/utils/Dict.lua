require "utils.table"

class "Dict"

local dict_methods = {
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

Dict:include(dict_methods, "value")

function Dict:init(t)
  assert(type(t) == "table", "table expected, got " .. type(t))

  if is_class(t) then
    local name = t.class:get_name()
    if name ~= "Dict" then
      error("Dict|table expected, got " .. name)
    else
      return t
    end
  else
    self.value = t
  end

  return self
end
