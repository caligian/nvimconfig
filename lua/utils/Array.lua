require "utils.Table"

class('Array', Table)

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


function Array:init(t)
  Array:super()(self, t)

  if t.get_name and t:get_name() == 'Array' then
    return t
  elseif t.is_a and t:is_a(Table) then
    self.value = t
  else
    self.value = t 
  end

  self.iterator = ipairs
end
