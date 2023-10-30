plugin = plugin
    or struct("plugin", {
        'spec',
        "name",
        'methods',
        "autocmds",
        "mappings",
        "setup",
        "config",
        "user_config_require_path",
        "config_require_path",
    })

plugin.plugins = plugin.plugins or {}

function plugin.init(self, name, opts)
    opts = opts
        or {
            autocmds = false,
            mappings = false,
            user_config_require_path = "user.plugins." .. name,
            config_require_path = "core.plugins." .. name,
        }

    opts = copy(opts)
    opts.name = name
	merge(self, opts)
	plugin.plugins[self.name] = self

    return opts
end

function plugin.set_mappings(self, mappings, compile)
    mappings = mappings or self.mappings
    if not mappings then
        return
    end

    return kbd.map_group(self.name, mappings, compile)
end

function plugin.load_config(self)
    local user_path = req2path(self.user_config_require_path)
    local builtin_path = req2path(self.config_require_path)
    local msg

    if builtin_path then
        msg = require(self.config_require_path)
    end

    if user_path then
        msg = require(self.user_config_require_path)
    end

    if not msg then return end

    plugin.set_autocmds(msg)
    plugin.set_mappings(msg)

    if msg.setup then msg:setup() end

    return msg
end

function plugin.set_autocmds(self, autocmds)
    return autocmd.map_group(string.upper(self.name), autocmds or self.autocmds or {})
end

function plugin.get(name, callback, args)
    local plugin = plugin.plugins[name] or plugin(name)
    callback = is_string(callback) and plugin[callback] or callback

    if not callback then
        return plugin
    end

    return callback(plugin, unpack(args or {}))
end

function plugin.load_configs()
    if req2path('user.plugins') then
        user_plugins = require 'user.plugins'
        assert(is_table(user_plugins), 'plugins should be a dict containing specs')
        merge(plugins, user_plugins)
    end

    each(plugin.plugins, function (_, plugin)
        plugin.load_config(plugin)
    end)
end

function plugin.load_plugin(name)
    return plugin.get(name, 'load_config')
end

function plugin.to_lazy_spec()
    local core = path.join(user.dir, 'lua', 'core', 'plugins.lua')
    local user_path = path.join(user.user_dir, 'lua', 'user', 'plugins.lua')

    core = require('core.plugins')

    if path.exists(user_path) then
        merge(core, require('user.plugins'))
    end

    assert(not is_empty(core), 'lazy: expected non-empty dict')

    for key, value in pairs(core) do
        if not plugin.plugins[key] then
            plugin.plugins[key] = plugin(key)
            plugin.plugins[key].spec = value

            local config = value.config
            plugin.plugins[key].spec = value
            plugin.plugins[key].spec.config = function()
                if config then
                    config()
                end

                plugin.load_config(plugin.plugins[key])
            end
        end
    end

    return core
end

function plugin.setup_lazy()
    require("lazy").setup(values(plugin.to_lazy_spec()))
end

function plugin.load()
    plugin.setup_lazy()
end
