new 'Colorscheme' {
  colorscheme = {},

  _init = function(self, name, config)
    config = config or {}

    V.asss(name)
    V.asst(config)

    self.name = name
    self.config = config

    return self
  end,

  apply = function(self, override)
    local config = self.config
    table.merge(config, override)

    if not table.isblank(config) then
      config.callback(config)
    else
      vim.cmd("color " .. self.name)
    end
  end,

  -- User config format
  --[[
  {
    colorscheme = config_table
  }
  --]]
  loadall = function(force)
    if not V.isblank(Colorscheme.colorscheme) and not force then
      return
    end

    local function get_name(p)
      return vim.fn.fnamemodify(p, ":t:r")
    end
    local builtin = V.glob(user.dir, "colors/*.vim")
    local user_themes = V.glob(user.user_dir, "colors/*.vim")
    local installed = V.glob(user.plugins_dir, "*/colors/*.vim")
    local configured_dir = path.join(user.dir, "lua", "core", "plugins", "colorscheme")
    local all = table.map(table.extend(builtin, user_themes, installed), get_name)
    local configured = {}
    local exclude = table.map(dir.getfiles(configured_dir), get_name)
    all = table.grep(all, function(c)
      if table.index(exclude, c) then
        return false
      else
        return true
      end
    end)

    table.each(exclude, function(name)
      if string.match_any(name, "colorscheme", "init") then
        return
      end

      local defaults = require("core.plugins.colorscheme." .. name) or {}
      local user_config = V.require("user.colorscheme." .. name) or {}

      table.teach(defaults, function(name, f)
        local callback
        if user_config[name] then
          V.asst(user_config[name])
          callback = function(_config)
            f(table.merge(_config or {}, user_config[name]))
          end
        else
          callback = f
        end
        configured[name] = { callback = callback }
      end)
    end)

    table.extend(all, table.keys(configured))
    table.each(all, function(name)
      local c
      if configured[name] then
        c = Colorscheme(name, configured[name])
      else
        c = Colorscheme(name)
      end
      Colorscheme.colorscheme[name] = c
    end)

    return Colorscheme.colorscheme
  end,

  reload = function()
    Colorschene.loadall(true)
  end,

  set = function(name, config)
    V.ass_s(name, "name")

    Colorscheme.loadall(force)

    local c = Colorscheme.colorscheme[name]

    if c then
      c:apply(conf)
      Colorscheme.current = c
    else
      error("Invalid colorscheme provided: " .. name)
    end

    return c
  end,

  setdefault = function(force)
    local color = user.plugins.colorscheme
    local req = color.colorscheme[color.colorscheme.use]
    local conf = color.config

    Colorscheme.set(req, conf or {})
  end,

  setlight = function()
    local color = user.plugins.colorscheme
    local req = color.colorscheme.light
    local conf = color.config or {}

    Colorscheme.set(req, conf)
  end,

  setdark = function()
    local color = user.plugins.colorscheme
    local req = color.colorscheme.dark
    local conf = color.config or {}

    Colorscheme.set(req, conf)
  end,
}
