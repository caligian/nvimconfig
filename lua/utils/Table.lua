require "utils.table"
require 'utils.Class'

local table_methods = table

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

local array_methods = {
  append = table.append,
  iappend = table.iappend,
  unshift = table.unshift,
  shift = table.shift,
  index = table.index,
  each = table.each,
  grep = table.grep,
  map = table.map,
  ieach = table.ieach,
  igrep = table.igrep,
  imap = table.imap,
  filter = table.filter,
  ifilter = table.ifilter,
  len = table.len,
  isblank = table.isblank,
  extend = table.extend,
  compare = table.compare,
  butlast = table.butlast,
  last = table.last,
  first = table.first,
  rest = table.rest,
  update = table.update,
  get = table.get,
  slice = table.slice,
  contains = table.contains,
  makepath = table.makepath,
  zip2 = table.zip2,
  zip = table.zip,
  flatten = table.flatten,
}

class 'Table'
class 'Array'
class 'Dict'

function Table:init(t)
  assert(type(t) == "table", "table expected, got " .. type(t))

  self.value = t
  self:include(table_methods, 'value')
end

function Array:init(t)
  assert(type(t) == "table", "table expected, got " .. type(t))

  self.value = t
  self.iterator = ipairs
  self:include(array_methods, 'value')
end

function Dict:init(t)
  assert(type(t) == "table", "table expected, got " .. type(t))

  self.value = t
  self.iterator = pairs
  self:include(dict_methods, 'value')
end
