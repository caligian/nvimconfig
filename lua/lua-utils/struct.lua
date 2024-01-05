require "lua-utils.utils"
require "lua-utils.table"

--- Create a struct module that creates struct instances. Unlike classes, these are pure dicts
--- > vector = struct('vector', {'x', 'y'})
--- > function vector.init(self, x, y) self.x = x; self.y = y; return self end
--- > a = vector(1, 2); b = vector(3, 4)
--- @class struct
--- @overload fun(name:string, attribs:list): table
struct = module "struct"

function is_struct(x)
  return mtget(x, "struct")
end

function struct.is_a(x, tp)
  return mtget(x, "type") == tp and is_struct(x)
end

function is_class(x)
  return mtget(x, "class")
end

function struct.similar(x, y)
  local x_attribs = keys(mtget(x, "attribs"))
  local y_attribs = mtget(y, "attribs")
  local n = #x_attribs
  local same = 0

  for i = 1, n do
    if y_attribs[x_attribs[i]] then
      same = same + 1
    end
  end

  return same == n
end

--- Get valid struct attributes
--- @param st table
--- @return dict
function struct.attribs(st)
  return mtget(st, "attribs")
end

function struct.eq(x, y, opts)
  opts = opts or {}
  if opts.absolute == nil then
    opts.absolute = true
  end

  return dict.compare(x, y, opts)
end

function struct.ne(x, y, opts)
  return not struct.eq(x, y, opts)
end

function struct:__call(name, attribs)
  local structmt = {
    __tostring = function(S)
      return dump(copy(S))
    end,
    type = name,
    struct = true,
  }

  local mod = {}

  function structmt:__index(key)
    return rawget(structmt, key)
  end

  function structmt:__newindex(key, value)
    if mtkeys[key] then
      mtset(structmt, key, value)
    else
      rawset(self, key, value)
    end
  end

  function structmt:__call(...)
    local obj = mtset({}, structmt)

    assert(mod.init, name .. " :no .init() defined for struct")
    return mod.init(obj, ...)
  end

  attribs = dict.fromkeys(attribs)
  structmt.attribs = attribs

  return setmetatable(mod, structmt)
end

function struct.name(x)
  return mtget(x, "type")
end
