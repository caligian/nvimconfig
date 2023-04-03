require 'utils.Table'

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

class('Dict', Table)

Dict:include(dict_methods, 'value')

function Dict:init(t)
  Dict:super()(self, t)

  if t.get_name and t:get_name() == 'Dict' then
    return t
  elseif t.is_a and t:is_a(Table) then
    self.value = t.value
  else
    self.value = t 
  end

  self.iterator = ipairs
end
