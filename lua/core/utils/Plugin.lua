Plugin = class 'Plugin'
user.plugins = user.plugins or {}

function Plugin:setspec(spec)
  self.spec = spec
end

function Plugin:init(name, spec)
  self.spec = spec
  self.name = name
   
  user.plugins[self.name] = self

  return self
end

function Plugin.setup()
  require 'core.plugins'
  req 'user.plugins'

  local all = {}
  local j = 1

  dict.each(user.plugins, function(name, conf)
    all[j] = conf.spec
    local current = all[j].config

    all[j].config = function ()
      local config = 'core.plugins.' .. conf.name
      local user_config = 'user.plugins.' .. conf.name

      if utils.req2path(config) then
        require(config)
      end

      if utils.req2path(user_config) then
        require(user_config)
      end

      if conf.autocmds then 
        Autocmd.bind(conf.autocmds) 
      end

      if conf.on_attach then conf:on_attach() end
      if current then current() end
      if conf.kbd then K.bind(conf.kbd) end
    end

    j = j + 1
  end)

  require('lazy').setup(all)
end

local mt = {}
plugin = setmetatable({}, mt)

function mt:__index(name)
  return user.plugins[name] or Plugin(name)
end

function mt:__newindex(name, conf)
  local exists = user.plugins[name] or Plugin(name) 
  return dict.merge(exists, conf)
end
