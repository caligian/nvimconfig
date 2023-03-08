class 'Colorscheme'

Colorscheme.colorscheme = {}

function Colorscheme._init(self, name, config)
	config = config or {}

	validate {
		colorscheme = { "string", name },
		["config"] = { "table", config },
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
function Colorscheme.loadall(force)
	if not isblank(Colorscheme.colorscheme) and not force then
		return
	end

	local function get_name(p)
		return vim.fn.fnamemodify(p, ":t:r")
	end
	local builtin = glob(user.dir, "colors/*.vim")
	local user_themes = glob(user.user_dir, "colors/*.vim")
	local installed = glob(user.plugins_dir, "*/colors/*.vim")
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

		teach(defaults, function(name, f)
			local callback
			if user_config[name] then
				validate {
					config = { "t", user_config[name] },
				}
				callback = function(_config)
					f(merge(_config or {}, user_config[name]))
				end
			else
				callback = f
			end
			configured[name] = { callback = callback }
		end)
	end)

	extend(all, keys(configured))
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

function Colorscheme.reload()
	Colorschene.loadall(true)
end

function Colorscheme.set(name, config)
    config = config or {}
	validate {
		colorscheme = { "s", name },
		config = { "t", config },
	}

	Colorscheme.loadall(force)

	local c = Colorscheme.colorscheme[name]

	if c then
		c:apply(config)
		Colorscheme.current = c
	else
		error("Invalid colorscheme provided: " .. name)
	end

	return c
end

function Colorscheme.setdefault(force)
	local color = user.plugins.colorscheme
	local req = color.colorscheme[color.colorscheme.use]
	local conf = color.config

	Colorscheme.set(req, conf or {})
end

function Colorscheme.setlight()
	local color = user.plugins.colorscheme
	local req = color.colorscheme.light
	local conf = color.config or {}

	Colorscheme.set(req, conf)
end

function Colorscheme.setdark()
	local color = user.plugins.colorscheme
	local req = color.colorscheme.dark
	local conf = color.config or {}

	Colorscheme.set(req, conf)
end
