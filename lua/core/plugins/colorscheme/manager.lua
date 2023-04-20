user.colorscheme.colorscheme = user.colorscheme.colorscheme or {}
local color = user.colorscheme
local state = color.colorscheme
local ex = Exception "Colorscheme"
ex.invalid_colorscheme = "valid colorscheme expected"

local function get(name)
  local out = state[name]
  ex.invalid_colorscheme:throw_unless(out)

  return out
end

function color.setdefault()
  color.apply(color[color.use] or "default", color.config)
end

function color.setdark()
  color.apply(color.dark or "default", color.dark_config or color.config)
end

function color.setlight()
  color.apply(color.light or "default", color.light_config or color.config)
end

function color.add(name, config)
  config = config or {}

  validate {
    colorscheme = { "string", name },
    ["?config"] = { "table", config },
  }

  return dict.update(state, name, { name = name, config = config })
end

function color.apply(name, override)
  local theme = get(name)
  local config = theme.config or {}
  dict.merge(config, override)
  local cb = config.callback
  config.callback = nil

  if cb then
    cb(config)
  else
    vim.cmd("color " .. theme.name)
  end
end

function color.loadall()
  local function get_name(p)
    return vim.fn.fnamemodify(p, ":t:r")
  end

  local builtin =
    array.extend(utils.glob(user.dir, "colors/*.vim"), utils.glob(user.dir, "colors/*.lua"))

  local user_themes = array.extend(
    utils.glob(user.user_dir, "colors/*.vim"),
    utils.glob(user.user_dir, "colors/*.lua")
  )

  local installed = array.extend(
    utils.glob(user.plugins_dir, "*/colors/*.vim"),
    utils.glob(user.plugins_dir, "*/colors/*.lua")
  )

  local configured_dir = path.join(user.dir, "lua", "core", "plugins", "colorscheme")

  local all = array.map(array.extend(builtin, user_themes, installed), get_name)

  local configured = {}

  local exclude = array.map(dir.getfiles(configured_dir), get_name)

  all = array.grep(all, function(c)
    if array.index(exclude, c) then
      return false
    else
      return true
    end
  end)

  array.each(exclude, function(name)
    if string.match_any(name, "manager", "init") then
      return
    end

    local defaults = req("core.plugins.colorscheme." .. name) or {}
    local user_config = req("user.colorscheme." .. name) or {}

    dict.each(defaults, function(c, f)
      local callback
      if user_config[c] then
        validate {
          config = { "t", user_config[c] },
        }
        callback = function(_config)
          f(dict.merge(_config or {}, user_config[c]))
        end
      else
        callback = f
      end

      color.add(c, { callback = callback })
    end)
  end)

  array.each(all, function(name)
    if configured[name] then
      color.add(name, configured[name])
    else
      color.add(name)
    end
  end)
end
