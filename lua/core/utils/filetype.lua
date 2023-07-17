require "core.utils.autocmd"
require "core.utils.kbd"
require "core.utils.lsp"

filetype = filetype or setmetatable({ filetypes = {}, id = 1, processes = {} }, { type = "module", name = "filetype" })

local function formatter_config_path_exists(p)
    p = array.to_array(p)
    for i = 1, #p do
        if path.exists(p[i]) then
            return true
        end
    end

    return false
end

function filetype.new(name)
    validate.filetype("string", name)

    local self = {}

    dict.merge(self, {
        name = name,
        augroup = "filetype_" .. name,
        user_config_require_path = "user.ft." .. name,
        config_require_path = "core.ft." .. name,
        autocmds = {},
        load_autocmds = function (autocmds)
            local out = {}
            dict.each(autocmds or self.autocmds, function (au_name, callback)
                au_name = 'filetype.' .. name .. '.' .. au_name
                out[au_name] = autocmd.map('FileType', {callback = callback, pattern = name, name = au_name})
            end)

            return out
        end,
        load_path = function(p)
            if not path.exists(p) then
                return
            end

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
            if not self.lsp_server then
                return
            end

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

            dict.each(autocmds, function(_, au_spec)
                au_spec.name = "filetype." .. self.name .. "." .. au_spec.name
            end)

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
            if is_a.string(rest) then
                rest = { desc = rest }
            end
            rest = deepcopy(rest)
            rest.name = "filetype." .. self.name .. "." .. rest.name
            rest.event = "FileType"
            rest.pattern = self.name
            return kbd.map(mode, ks, cb, rest)
        end,
        load_mappings = function(self, mappings)
            mappings = mappings or self.mappings

            if not mappings then
                return
            end

            local out = {}
            local opts = mappings.opts

            dict.each(mappings, function(name, spec)
                if name == "opts" then
                    return
                end

                if opts then
                    local mode, ks, cb, rest
                    ks, cb, rest = unpack(spec)
                    rest = dict.merge(rest or {}, opts)
                    rest.name = "filetype." .. self.name .. "." .. name
                    mode = rest.mode or "n"
                    spec = { mode, ks, cb, rest }

                    apply(kbd.map, spec)
                else
                    spec = deepcopy(spec)
                    local mode, ks, cb, rest = unpack(spec)
                    rest = rest or {}
                    rest.name = "filetype." .. self.name .. "." .. name
                    spec[4] = rest

                    apply(kbd.map, spec)
                end
            end)
        end,
        format_dir = function(self, p, opts)
            local exists = filetype.processes[p]
            if exists and exists:is_running() then
                local userint = vim.fn.input("stop process for " .. p .. " (y for yes) % ")
                if userint == "y" then
                    exists:stop()
                else
                    return exists
                end
            end

            opts = opts or self.dir_formatter or {}

            if is_empty(opts) then
                return nil, "no directory formatter for filetype " .. self.name
            end

            if not path.isdir(p) then
                return nil, "invalid directory " .. p
            end

            local cmd = opts[1]
            local args = opts.args

            if not cmd then
                return nil, "no command given for " .. self.name
            end

            if is_a.array(args) and not formatter_config_path_exists(self.formatter_local_config_path) then
                cmd = cmd .. " " .. array.join(args, " ")
            end

            local append_dirname = opts.append_dirname

            if append_dirname then
                p = p:gsub("~", os.getenv "HOME")
                p = p:gsub("%$HOME", os.getenv "HOME")
                p = p:gsub("%$XDG_CONFIG", path.join(os.getenv "HOME", ".config"))
                cmd = cmd .. " " .. path.abspath(p)
            end

            local proc = process.new(cmd, {
                on_exit = function(j)
                    local err = j.stderr
                    local out = j.stdout

                    if not ((#err == 1 and #err[1] == 0) or #err == 0) then
                        to_stderr(array.join(err, "\n"))
                        return
                    end

                    if #out == 0 then
                        vim.notify("successfully ran command " .. cmd)
                        return
                    else
                        vim.notify("successfully ran command " .. cmd .. "\n" .. array.join(j.stdout, "\n"))
                    end
                end,
            })

            proc:start()

            filetype.processes[p] = proc

            return proc
        end,
        format_buffer = function(self, bufnr, opts)
            opts = opts or self.formatter
            if not opts or is_empty(opts) then
                return nil, "no formatter for filetype " .. self.name
            end

            bufnr = bufnr or buffer.bufnr()
            local cmd = opts.cmd or opts[1]
            local args = opts.args

            if formatter_config_path_exists(self.formatter_local_config_path) then
                args = {}
            end

            if is_a.array(args) then
                cmd = cmd .. " " .. array.join(args, " ")
            end

            bufnr = bufnr or buffer.bufnr()

            local stdin = opts.stdin
            local write = opts.write
            local append_filename = opts.append_filename
            local bufname = buffer.name(bufnr)

            if stdin then
                cmd = "cat " .. buffer.name(bufnr) .. " | " .. cmd
            elseif append_filename then
                cmd = cmd .. " " .. bufname
            end

            vim.cmd(":w! " .. bufname)
            buffer.set_option(bufnr, "modifiable", false)

            local winnr = buffer.winnr(bufnr)
            local view = winnr and win.save_view(winnr)
            local proc = process.new(cmd, {
                on_exit = function(proc)
                    local bufnr = bufnr
                    local name = bufname

                    buffer.set_option(bufnr, "modifiable", true)

                    if write then
                        buffer.call(bufnr, function()
                            vim.cmd(":e! " .. bufname)
                            if view then
                                win.restore_view(winnr, view)
                            end
                        end)

                        return
                    end

                    local err = proc.stderr
                    if not ((#err == 1 and #err[1] == 0) or #err == 0) then
                        to_stderr(array.join(err, "\n"))
                        return
                    end

                    local out = proc.stdout
                    if #out == 0 then
                        return
                    end

                    local bufnr = bufnr
                    buffer.set_lines(bufnr, 0, -1, out)

                    if view then
                        win.restore_view(winnr, view)
                    end
                end,
            })

            local exists = filetype.processes[bufname]
            if exists and exists:is_running() then
                local userint = input {
                    "userint",
                    "Stop existing process for " .. bufname .. "? (y for yes)",
                }
                if userint.userint:match "y" then
                    exists:stop()
                end
            end

            filetype.processes[bufname] = proc
            proc:start()

            return proc
        end,
    })

    filetype.filetypes[name] = self
    return self
end

filetype.get = multimethod.new {
    string = function(ft)
        if not filetype.filetypes[ft] then
            filetype.filetypes[ft] = filetype.new(ft)
        end
        return filetype.filetypes[ft]
    end,
    [{ "string", "string" }] = function(ft, attrib)
        return filetype.get(ft)[attrib]
    end,
    [{ "string", "string", "callable" }] = function(ft, attrib, callback)
        ft = filetype.get(ft)
        attrib = ft[attrib]

        if attrib ~= nil then
            return callback(attrib, ft)
        end
    end,
    [{ "string", "callback" }] = function(ft, callback)
        return callback(filetype.get(ft))
    end,
}

function filetype.format_buffer(ft, bufnr, opts)
    return filetype.get(ft, "formatter", function(config, ft_obj)
        if opts then
            config = dict.merge(copy(config), opts)
        end
        return ft_obj:format_buffer(bufnr, config)
    end)
end

function filetype.format_dir(ft, p, opts)
    return filetype.get(ft, "dir_formatter", function(_, ft_obj)
        return ft_obj:format_dir(p)
    end)
end

function filetype.load_defaults(ft)
    local p = "core.ft." .. ft
    if req2path(p) then
        return require(p)
    end
end

function filetype.load_specs(is_user)
    if not is_user then
        array.each(dir.getallfiles(user.dir .. "/lua/core/ft/"), function(f)
            require("core.ft." .. path.basename(f:gsub("%.lua$", "")))
        end)
    else
        array.each(dir.getallfiles(user.user_dir .. "/lua/user/ft/"), function(f)
            require("core.ft." .. path.basename(f:gsub("%.lua$", "")))
        end)
    end
end
