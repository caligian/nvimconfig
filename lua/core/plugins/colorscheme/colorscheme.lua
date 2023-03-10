class "Colorscheme"

Colorscheme.colorscheme = {}

function Colorscheme._init(self, name, config)
  config = config or {}

  validate {
    colorscheme = { "string", name },
    ["?config"] = { "table", config },
  }

  self.name = name
  self.config = config

  return self
end

function Colorscheme.apply(self, override)
  local config = self.config

  merge(config, override)

  if not isblank(config) then
    config.callback(config)
  else
    vim.cmd("color " .. self.name)
  end
end

-- User config format
--[[
{
colorscheme = config_table
}
--]]
function Colorscheme.loadall()
  local function get_name(p)
    return vim.fn.fnamemodify(p, ":t:r")
  end
  local builtin = extend(glob(user.dir, "colors/*.vim"), glob(user.dir, "colors/*.lua"))
  local user_themes =
    extend(glob(user.user_dir, "colors/*.vim"), glob(user.user_dir, "colors/*.lua"))
  local installed =
    extend(glob(user.plugins_dir, "*/colors/*.vim"), glob(user.plugins_dir, "*/colors/*.lua"))
  local configured_dir = path.join(user.dir, "lua", "core", "plugins", "colorscheme")
  local all = map(extend(builtin, user_themes, installed), get_name)
  local configured = {}
  local exclude = map(dir.getfiles(configured_dir), get_name)

  all = grep(all, function(c)
    if index(exclude, c) then
      return false
    else
      return true
    end
  end)

  each(exclude, function(name)
    if match(name, "colorscheme", "init") then
      return
    end

    local defaults = require("core.plugins.colorscheme." .. name) or {}
    local user_config = req("user.colorscheme." .. name) or {}

    teach(defaults, function(color, f)
      local callback
      if user_config[name] then
        validate {
          config = { "t", user_config[color] },
        }
        callback = function(_config)
          f(merge(_config or {}, user_config[color]))
        end
      else
        callback = f
      end
      configured[name] = { callback = callback }
    end)
  end)

  -- extend(all, keys(configured), map(installed, get_name), map(user_themes, get_name))

  each(all, function(name)
    local c
    if configured[name] then
      c = Colorscheme(name, configured[name])
    else
      c = Colorscheme(name)
    end
    Colorscheme.colorscheme[name] = c
  end)

  return Colorscheme.colorscheme
end

function Colorscheme.set(name, config)
  config = config or {}

  validate {
    colorscheme = { "s", name },
    config = { "t", config },
  }

  Colorscheme.loadall()

  local c = Colorscheme.colorscheme[name]

  if c then
    c:apply(config)
    Colorscheme.current = c
  else
    error("Invalid colorscheme provided: " .. name)
  end

  return c
end

function Colorscheme.setdefault()
  local color = user.plugins.colorscheme
  local required = color.colorscheme[color.colorscheme.use]
  local conf = color.config

  Colorscheme.set(required, conf or {})
end

function Colorscheme.setlight()
  local color = user.plugins.colorscheme
  local required = color.colorscheme.light
  local conf = color.config or {}

  Colorscheme.set(required, conf)
end

function Colorscheme.setdark()
  local color = user.plugins.colorscheme
  local required = color.colorscheme.dark
  local conf = color.config or {}

  Colorscheme.set(required, conf)
end
