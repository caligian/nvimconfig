local lazy = require "lazy"
user.plugins = {}
local state = user.plugins

--------------------------------------------------------------------------------
Plugin = class "Plugin"

function Plugin.load_configs() 
  if Plugin.loaded then return end
  Plugin.loaded = true
  require "core.plugins.plugins" 
end

function Plugin.loadall()
  Plugin.load_configs()

  lazy.setup(
    array.map(dict.values(state), function(x) return x.spec end),
    { lazy = true }
  )
end

function Plugin.exists(name) return state[name] ~= nil end

function Plugin:load()
  req("core.plugins." .. self.name)
  req("user.plugins." .. self.name)

  if self.setup then self:setup() end
  if self.kbd then K.bind(self.kbd) end
  if self.autocmds then Autocmd.bind(self.autocmds) end
end

function Plugin:setup()
  if self.kbd then K.bind(self.kbd) end
  if self.autocmds then Autocmd.bind(self.autocmds) end

  return self
end

function Plugin:init(name, conf)
  conf = conf or {}
  conf.spec = conf.spec or {}
  conf.spec.config = conf.spec.config or function() self:load() end
  self.name = name
  state[name] = dict.merge(self, conf)
end

function Plugin.create_kbd(kbd)
  local mt = {}
  setmetatable(kbd, mt)

  function mt:__call(setup_fn, ...) setup_fn(self, ...) end

  return kbd
end

function Plugin.get(name) return state[name] end

function Plugin.create(name, conf)
  if not Plugin.exists(name) then
    return Plugin(name, conf)
  else
    return state[name]
  end
end

function Plugin:wrap(callback)
  return function(...) callback(self, ...) end
end

plugin = setmetatable({}, {
  __call = function(self, name)
    return function(conf) return Plugin.create(name, { spec = conf }) end
  end,

  __index = function(self, name) return Plugin.create(name) end,

  __newindex = function(self, name, conf)
    local plugin = Plugin.create(name)
    dict.merge(plugin, conf)
  end,
})

return Plugin
