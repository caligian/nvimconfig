require "core.utils.au"
require "core.utils.kbd"
require "core.utils.logger"

if not plugin then
  plugin = class "plugin"
  plugin.plugins = {}
end

function plugin.init(self, name, opts)
  if isstring(name) and plugin.plugins[name] then
    return plugin.plugins[name]
  elseif istable(name) then
    assertisa(name.name, "string")
    return plugin(name.name, name)
  end

  opts = opts
    or {
      autocmds = false,
      mappings = false,
      user_config_require_path = "user.plugins." .. name,
      config_require_path = "core.plugins." .. name,
      methods = {},
      setup = function() end,
      spec = {},
    }

  opts = copy(opts)
  opts.name = name
  dict.merge(self, opts)
  plugin.plugins[self.name] = self

  return self
end

function plugin.list()
  local p = path.join(
    vim.fn.stdpath "config",
    "lua",
    "core",
    "plugins"
  )

  local fs = glob(p, "*")
  fs = list.filter(fs, function(x)
    if path.isdir(x) then
      local xp = path.join(p, "init.lua")
      if path.isfile(xp) then
        return true
      end
    elseif path.isfile(x) and x:match "%.lua$" then
      return true
    end
  end, function(x)
    return (path.basename(x):gsub("%.lua", ""))
  end)

  return fs
end

local function conv(name)
  if isstring(name) then
    if plugin.plugins[name] then
      return plugin.plugins[name]
    else
      return plugin(name)
    end
  elseif istable(name) then
    if not name.name then
      return
    else
      return plugin(name.name, name)
    end
  end
end

function plugin.loadfile(self)
  self = conv(self)
  if not self then
    return
  end

  local name = self.name
  local luapath = req2path("core.plugins." .. name)
  local userluapath = req2path("user.plugins." .. name)
  local builtin, userconfig

  if not luapath and not userluapath then
    return
  end

  builtin = luapath and loadfile(luapath)
  userconfig = userluapath and loadfile(userluapath)

  local plug = plugin(name)
  local _, okuserconfig

  if isfunction(userconfig) then
    _, userconfig = pcall(userconfig)
  end

  if isfunction(builtin) then
    _, builtin = pcall(builtin)
  end

  if istable(builtin) and istable(userconfig) then
    dict.merge(plug, builtin, userconfig)
  elseif not builtin and not userconfig then
    return plug
  elseif istable(builtin) then
    dict.merge(plug, builtin)
  elseif istable(userconfig) then
    dict.merge(plug, userconfig)
  end

  return plug
end

function plugin.require(self)
  self = conv(self)
  if not self then
    return
  end

  local name = self.name
  local luapath = req2path("core.plugins." .. name)
  local userluapath = req2path("user.plugins." .. name)
  local builtin, userconfig

  builtin = requirex("core.plugins." .. name)
  userconfig = requirex("user.plugins." .. name)
  local plug = plugin(name)

  if istable(builtin) and istable(userconfig) then
    dict.merge(plug, builtin, userconfig)
  elseif not builtin and not userconfig then
    return plug
  elseif istable(builtin) then
    dict.merge(plug, builtin)
  elseif istable(userconfig) then
    dict.merge(plug, userconfig)
  end

  return plug
end

function plugin.configure(self)
  self = conv(self)
  if not self then
    return
  end

  if self.setup then
    self:setup()
  end

  self:set_autocmds()
  self:set_mappings()

  return self
end

function plugin.loadfileall()
  local out = {}
  list.each(plugin.list(), function(x)
    local m = requirem("core.plugins." .. x)
    if istable(m) then
      out[x] = plugin(x, m)
      out[x]:loadfile()
    end
  end)

  return out
end

function plugin.requireall()
  local out = {}
  list.each(plugin.list(), function(x)
    local m = requirem("core.plugins." .. x)
    if istable(m) then
      out[x] = plugin(x, m)
      out[x]:require()
    end
  end)

  return out
end

function plugin.set_autocmds(self, autocmds)
  autocmds = autocmds or self.autocmds
  if not autocmds or size(self.autocmds) == 0 then
    return
  end

  dict.each(autocmds, function(name, spec)
    name = "plugin." .. self.name .. "." .. name
    spec[2] = spec[2] or {}
    spec[2].name = name
    au.map(unpack(spec))
  end)
end

function plugin.set_mappings(self, mappings)
  mappings = mappings or self.mappings
  if not mappings or size(self.mappings) == 0 then
    return
  end

  local opts = mappings.opts or {}
  local mode = opts.mode or "n"
  dict.each(mappings, function(name, spec)
    if name == "opts" then
      return
    end

    assert(#spec >= 3, "expected at least 3 arguments")

    if #spec ~= 4 then
      list.lappend(spec, mode)
    end

    name = "plugin." .. self.name .. "." .. name
    spec[4] = spec[4] or {}
    spec[4] = isstring(spec[4]) and { desc = spec[4] }
      or spec[4]

    dict.merge(spec[4], opts)

    spec[4].name = name
    kbd.map(unpack(spec))
  end)
end

function plugin.configureall()
  list.each(plugin.list(), function(x)
    local plug = plugin(x)
    plug:require()
    plug:configure()
  end)
end

function plugin.lazy_spec()
  local corepath =
    path.join(user.dir, "lua", "core", "plugins.lua")
  local userpath =
    path.join(user.user_dir, "lua", "user", "plugins.lua")
  local core = requirex "core.plugins"
  local userconfig = requirex "user.plugins"

  if not core and not userconfig then
  elseif core then
    assertisa(core, "table")
  end

  if userconfig then
    assertisa(userconfig, "table")
    dict.merge(core, userconfig)
  end

  local specs = {}
  dict.each(core, function(name, spec)
    assertisa(spec[1], "string")

    local conf = spec.config
    function spec.config()
      local ok, msg = pcall(function()
        local plug = plugin(name)
        plug:require()
        plug:configure()

        if conf and isfunction(conf) then
          conf()
        end
      end)

      if not ok then
        print(msg)
      end
    end

    specs[#specs + 1] = spec
  end)

  return specs
end

function plugin.setup_lazy()
  require("lazy").setup(plugin.lazy_spec())
end

function plugin.main()
  plugin.setup_lazy()
end
