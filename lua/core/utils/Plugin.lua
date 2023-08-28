Plugin = Plugin
    or struct("Plugin", {
        "name",
        'methods',
        "autocmds",
        "mappings",
        "setup",
        "config",
        "user_config_require_path",
        "config_require_path",
    })

Plugin.Plugins = Plugin.Plugins or {}

function Plugin.init_before(name, opts)
    opts = opts
        or {
            autocmds = false,
            mappings = false,
            user_config_require_path = "user.plugins." .. name,
            config_require_path = "core.plugins." .. name,
        }
    opts = copy(opts)
    opts.name = name

    return opts
end

function Plugin.init(self)
    Plugin.Plugins[self.name] = self
    return self
end

function Plugin.set_mappings(self, mappings, compile)
    mappings = mappings or self.mappings
    if not mappings then
        return
    end

    return kbd.map_group(self.name, mappings, compile)
end

function Plugin.load_config(self)
    local user_path = req2path(self.user_config_require_path)
    local builtin_path = req2path(self.config_require_path)
    local msg

    if builtin_path then
        msg = logger.pcall(require, self.config_require_path)
    end

    if user_path then
        msg = logger.pcall(require, self.user_config_require_path)
    end

    if not msg then return end

    Plugin.set_autocmds(msg)
    Plugin.set_mappings(msg)

    if msg.setup then msg:setup() end

    return msg
end

function Plugin.set_autocmds(self, autocmds)
    return autocmd.map_group(string.upper(self.name), autocmds or self.autocmds or {})
end

function Plugin.get(name, callback, args)
    local plugin = Plugin.Plugins[name] or Plugin(name)
    callback = is_string(callback) and Plugin[callback] or callback

    if not callback then
        return plugin
    end

    return callback(plugin, unpack(args or {}))
end

function Plugin.load_configs()
    if req2path('user.plugins') then
        user_plugins = require 'user.plugins'

        assert(is_table(user_plugins), 'plugins should be a dict containing specs')

        dict.merge(plugins, user_plugins)
    end

    dict.each(Plugin.Plugins, function (_, plugin)
        Plugin.load_config(plugin)
    end)
end

function Plugin.load_plugin(name)
    return Plugin.get(name, 'load_config')
end

function Plugin.load_config_dir()
    local d1_req = 'core.plugins'
    local d2_req = 'user.plugins'
    local d1_path = req2path(d1_req)
    local d2_path = req2path(d2_req)
    local d1, d2
    local plugins = {}

    if d1_path then
        d1 = array.map(dir.getfiles(d1_path), function (c) return string.gsub(path.basename(c), '.lua', '') end)
        d1 = array.extend(d1, array.map(dir.getdirectories(d1_path), path.basename))
        d1 = is_empty(d2) and false or d1
    end

    if d2_path then
        d2 = array.map(dir.getfiles(d2_path), function (c) return string.gsub(path.basename(c), '.lua', '') end)
        d2 = array.extend(d2, array.map(dir.getdirectories(d2_path), path.basename))
        d2 = is_empty(d2) and false or d2
    end

    if d2 then
        if d1 then
            array.each(d1, function (req)
                pcall(require, 'core.plugins.' .. req)
            end)
        end

        array.each(d2, function (req)
            local msg = logger.pcall(require, 'user.plugins.' .. req)

            if plugins[msg.name] then
                dict.merge(msg, plugins[msg.name])
                if msg.setup then
                    msg:setup()
                end
            elseif ok and msg and msg.setup then
                msg:setup()
            end
        end)
    else
        array.each(d1, function (req)
            local plugin = Plugin.get(req)
            Plugin.load_config(plugin)
        end)
    end
end

function Plugin.to_lazy_spec()
    local core = path.join(user.dir, 'lua', 'core', 'plugins.lua')
    local user_path = path.join(user.user_dir, 'lua', 'user', 'plugins.lua')

    core = require('core.plugins')

    if path.exists(user_path) then
        merge(core, require('user.plugins'))
    end

    assert(not is_empty(core), 'lazy: expected non-empty dict')

    return core
end

function Plugin.setup_lazy()
    local core = Plugin.to_lazy_spec()
    array.map(keys(core), function (plugin) return Plugin(plugin) end)

    require("lazy").setup(values(core))
end
