require "utils.table"

class "Array"

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

Array:include(array_methods)

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
