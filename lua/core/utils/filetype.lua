require "core.utils.autocmd"
require "core.utils.kbd"
require "core.utils.lsp"

local mt = {}
filetype = setmetatable({ filetypes = {}, id = 1 }, mt)

function filetype.new(name)
    validate.filetype("string", name)

    local self = {
        name = name,
        augroup = "filetype_" .. name,
        user_config_require_path = "user.ft." .. name,
        config_require_path = "core.ft." .. name,
        load_path = function(p)
            if not path.exists(p) then return end

            local out
            local ok, msg = pcall(loadfile, p)
            if ok and msg then
                ok = msg()
                if is_a.callable(ok) then
                    out = ok()
                end
            end

            return out or true
        end,
        setup_lsp = function(self)
            if not self.lsp_server then return end

            local server, config
            if is_a.string(self.lsp_server) then
                server = self.lsp_server
                config = {}
            else
                local lsp_server = copy(self.lsp_server)
                server = lsp_server[1]
                lsp_server[1] = nil
                config = lsp_server
            end

           lsp.setup_server(server, config)

            return true
        end,
        load_config = function(self, is_user)
            local ok, msg
            if is_user then
                ok, msg = pcall(require, self.user_config_require_path)
            else
                ok, msg = pcall(require, self.config_require_path)
            end

            if ok and msg then
                ok = msg()
                if is_a.callable(ok) then
                    out = ok()
                end
            end

            return out or true
        end,
        reload_config = function(self, is_user)
            if is_user then
                return self:load_config(req2path(self.user_config_require_path))
            else
                return self:load_config(req2path(self.config_require_path))
            end
        end,
        add_autocmd = function(self, opts)
            opts = opts or {}
            opts = deepcopy(opts)
            opts.group = self.augroup
            opts.pattern = self.name

            return autocmd.new("FileType", opts)
        end,
        add_autocmds_with_opts = function(self, opts, autocmds)
            opts = deepcopy(opts)
            opts.group = self.augroup
            opts.event = "FileType"
            opts.pattern = self.name

            autocmds = deepcopy(autocmds)

            dict.each(
                autocmds,
                function(_, au_spec)
                    au_spec.name = "filetype."
                        .. self.name
                        .. "."
                        .. au_spec.name
                end
            )

            autocmd.map_with_opts(opts, autocmds)
        end,
        map_with_opts = function(self, opts, mappings)
            opts = deepcopy(opts)
            opts.apply = function(mode, ks, cb, rest)
                rest.pattern = self.name
                rest.event = "FileType"
                rest.name = "filetype." .. self.name .. "." .. rest.name
                return mode, ks, cb, rest
            end
            kbd.map_with_opts(opts, mappings)
        end,
        map = function(self, mode, ks, cb, rest)
            if is_a.string(rest) then rest = { desc = rest } end
            rest = deepcopy(rest)
            rest.name = "filetype." .. self.name .. "." .. rest.name
            rest.event = "FileType"
            rest.pattern = self.name
            return kbd.map(mode, ks, cb, rest)
        end,
        load_mappings = function(self, mappings)
            mappings = mappings or self.mappings

            if not mappings then return end

            local out = {}
            local opts = mappings.opts

            dict.each(mappings, function(name, spec)
                if name == "opts" then return end

                if opts then
                    local mode, ks, cb, rest
                    ks, cb, rest = unpack(spec)
                    rest = dict.merge(rest or {}, opts)
                    rest.name = "filetype." .. self.name .. '.' .. name
                    mode = rest.mode or "n"
                    spec = { mode, ks, cb, rest }

                    apply(kbd.map, spec)
                else
                    spec = deepcopy(spec)
                    local mode, ks, cb, rest = unpack(spec)
                    rest = rest or {}
                    rest.name = "filetype." .. self.name .. '.' .. name
                    spec[4] = rest

                    apply(kbd.map, spec)
                end
            end)
        end,
    }

    filetype.filetypes[name] = self
    return self
end

function filetype.get(ft, attrib)
    if not filetype.filetypes[ft] then
        filetype.filetypes[ft] = filetype.new(ft)
    end
    if attrib then return filetype.filetypes[ft][attrib] end
    return filetype.filetypes[ft]
end

function filetype.load_specs(is_user)
    if not is_user then
        array.each(
            dir.getallfiles(user.dir .. "/lua/core/ft/"),
            function(f)
                require("core.ft." .. path.basename(f:gsub("%.lua$", "")))
            end
        )
    else
        array.each(
            dir.getallfiles(user.user_dir .. "/lua/user/ft/"),
            function(f)
                require("core.ft." .. path.basename(f:gsub("%.lua$", "")))
            end
        )
    end
end

return filetype
