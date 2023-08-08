require "core.utils.autocmd"
require "core.utils.kbd"
require "core.utils.lsp"
require "lua-utils.class"

Filetype = Filetype
    or struct.new("Filetype", {
        "name",
        "augroup",
        "user_config_require_path",
        "config_require_path",
        "autocmds",
        "mappings",
        "compile",
        "repl",
        "test",
        "build",
        "lsp_server",
        "formatter",
        "formatter_local_config_path",
        "dir_formatter",
        "linters",
    })

Filetype.filetypes = Filetype.filetypes or {}
Filetype.id = Filetype.filetypes or 1
Filetype.processes = Filetype.filetypes or {}

local function formatter_config_path_exists(p)
    p = array.to_array(p)
    for i = 1, #p do
        if path.exists(p[i]) then
            return true
        end
    end

    return false
end

function Filetype.init_before(name)
    return { name = name, user_config_require_path = "user.ft." .. name, config_require_path = "core.ft." .. name }
end

function Filetype.init(self)
    if Filetype.filetypes[self.name] then
        return Filetype.filetypes[self.name]
    end

    return self
end

function Filetype.load_autocmds(self, autocmds)
    autocmds = autocmds or self.autocmds
    if not autocmds then
        return
    end

    local out = {}
    dict.each(autocmds, function(au_name, callback)
        au_name = self.name .. "." .. au_name
        out[au_name] = autocmd.map("FileType", { callback = callback, pattern = self.name, name = au_name })
    end)

    return out
end

function Filetype.load_path(self, p)
    p = p or req2path(self.config_require_path)
    local out = loadfile(p)()

    if self.mappings and not is_empty(self.mappings) then
        Filetype.load_mappings(self)
    end

    if self.autocmds and not is_empty(self.autocmds) then
        Filetype.load_autocmds(self)
    end

    if out then
        Filetype.filetypes[self.name] = out
    end

    return out or true
end

function Filetype.setup_lsp(self)
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
end

function Filetype.load_config(self, is_user)
    local old_self = self
    if is_user then
        self = reqloadfile(self.user_config_require_path)
    else
        self = reqloadfile(self.config_require_path)
    end

    if self then
        Filetype.filetypes[self.name] = self
        Filetype.load_autocmds(self)
        Filetype.load_mappings(self)
    end

    Filetype.load_autocmds(old_self)
    Filetype.load_mappings(old_self)
    return old_self
end

function Filetype.reload_config(self, is_user)
    if is_user then
        return Filetype.load_config(self, req2path(self.user_config_require_path))
    else
        return Filetype.load_config(self, req2path(self.config_require_path))
    end
end

function Filetype.add_autocmd(self, opts)
    opts = opts or {}
    opts = deepcopy(opts)
    opts.group = self.augroup
    opts.pattern = self.name

    return autocmd.new("FileType", opts)
end

function Filetype.add_autocmds_with_opts(self, opts, autocmds)
    opts = deepcopy(opts)
    opts.group = self.augroup
    opts.event = "FileType"
    opts.pattern = self.name

    autocmds = deepcopy(autocmds)

    dict.each(autocmds, function(_, au_spec)
        au_spec.name = "Filetype." .. self.name .. "." .. au_spec.name
    end)

    autocmd.map_with_opts(opts, autocmds)
end

function Filetype.map_with_opts(self, opts, mappings)
    opts = deepcopy(opts)
    opts.apply = function(mode, ks, cb, rest)
        rest.pattern = self.name
        rest.event = "FileType"
        rest.name = "Filetype." .. self.name .. "." .. rest.name
        return mode, ks, cb, rest
    end
    kbd.map_with_opts(opts, mappings)
end

function Filetype.map(self, mode, ks, cb, rest)
    if is_a.string(rest) then
        rest = { desc = rest }
    end
    rest = deepcopy(rest)
    rest.name = "Filetype." .. self.name .. "." .. rest.name
    rest.event = "FileType"
    rest.pattern = self.name
    return kbd.map(mode, ks, cb, rest)
end

function Filetype.load_mappings(self, mappings)
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
            rest = is_a.string(rest) and { desc = rest } or rest
            rest = dict.merge(rest or {}, opts)
            rest.name = self.name .. "." .. name
            rest.event = "FileType"
            rest.pattern = self.name
            mode = rest.mode or "n"
            spec = { mode, ks, cb, rest }
            apply(kbd.map, spec)
        else
            spec = deepcopy(spec)
            local mode, ks, cb, rest = unpack(spec)
            rest = is_a.string(rest) and { desc = rest } or rest
            rest = rest or {}
            rest.name = self.name .. "." .. name
            rest.event = "FileType"
            rest.pattern = self.name
            spec[4] = rest
            apply(kbd.map, spec)
        end
    end)
end

function Filetype.format_dir(self, p, opts)
    local exists = Filetype.processes[p]
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

    Filetype.processes[p] = proc

    return proc
end

function Filetype.format_buffer(self, bufnr, opts)
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

    local exists = Filetype.processes[bufname]
    if exists and exists:is_running() then
        local userint = input {
            "userint",
            "Stop existing process for " .. bufname .. "? (y for yes)",
        }
        if userint.userint:match "y" then
            exists:stop()
        end
    end

    Filetype.processes[bufname] = proc
    proc:start()

    return proc
end

function Filetype.get(ft, attrib, callback)
    local x = Filetype(ft)

    if attrib then
        x = x[attrib]
        if callback then 
            return callback(x) 
        else
            return x
        end
    elseif callback then
        return callback(x)
    else
        return x
    end
end

function Filetype.load_defaults(ft)
    local p = "core.ft." .. ft
    if req2path(p) then return require(p) end
end

function Filetype.load_specs(is_user)
    if not is_user then
        array.each(dir.getallfiles(user.dir .. "/lua/core/ft/"), function(f)
            f = path.basename(f):gsub("%.lua$", "")
            Filetype.load_config(Filetype(f))
        end)
    else
        array.each(dir.getallfiles(user.user_dir .. "/lua/user/ft/"), function(f)
            f = path.basename(f):gsub("%.lua$", "")
            Filetype.load_config(Filetype(f), true)
        end)
    end
end
