require "core.utils.autocmd"
require "core.utils.kbd"
require "core.utils.lsp"
require "core.utils.job"

local add_ft = vim.filetype.add

filetype = filetype
    or struct("filetype", {
        "actions",
        "abbrevs",
        "name",
        "filetype",
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

-- filetype.filetypes = filetype.filetypes or {}
filetype.filetypes = filetype.filetypes or {}
filetype.id = #filetype.filetypes or 1
filetype.processes = filetype.processes or {}

local function resolve(ft_or_bufnr_self)
    if is_string(ft_or_bufnr_self) then
        return ft_or_bufnr_self
    elseif is_object(ft_or_bufnr_self, "filetype") then
        return ft_or_bufnr_self
    elseif is_number(ft_or_bufnr_self) then
        return buffer.option(ft_or_bufnr_self, "filetype")
    else
        error("invalid spec " .. dump(ft_or_bufnr_self))
    end
end

function resolvebuf(buf)
    return buffer.bufnr(buf or buffer.current())
end

function filetype.get_by_buf(buf, callback)
    local exists = filetype.filetypes[buffer.filetype(resolvebuf(buf))]
    if not exists then
        return
    end

    if callback then return callback(exists) end
    return exists
end

local function formatter_config_path_exists(p)
    p = to_list(p)

    for i = 1, #p do
        if path.exists(p[i]) then
            return true
        end
    end

    return false
end

function filetype.init(self, name)
    name = resolve(name)
    if filetype.filetypes[name] then
        return filetype.filetypes[name]
    end
    filetype.filetypes[name] = self

    self.name = name
    self.user_config_require_path = "user.ft." .. name
    self.config_require_path = "core.ft." .. name

    return self
end

-- run when in a workspace
function filetype.create_actions_picker(bufnr)
    bufnr = bufnr or buffer.bufnr()
    local ft = buffer.option(bufnr, "filetype")
    local specs = filetype.get(ft, "actions")
    local p = buffer.name(bufnr)
    local workspace

    if not specs or is_empty(specs) then
        return false
    else
        specs = vim.deepcopy(specs)
    end

    workspace = filetype.workspace(bufnr)
    if not specs.buffer and not specs.workspace then
        return false
    elseif workspace and specs.workspace then
        specs = specs.workspace
    elseif buffer and specs.buffer then
        specs = specs.buffer
    else
        return false
    end

    local t = load_telescope()

    local default = specs.default
    if not default then
        error "no default action provided"
    end

    local results = {
        results = keys(specs),
        entry_maker = function(x)
            if workspace then
                return {
                    value = x,
                    ordinal = x,
                    display = sprintf("(%s) %s", workspace, x),
                    workspace = workspace,
                }
            end

            return {
                value = x,
                ordinal = x,
                display = x,
            }
        end,
    }

    local prompt_title
    do
        if not in_workspace then
            prompt_title = "actions for " .. p
        else
            prompt_title = "actions for (workspace) " .. workspace
        end
    end

    local t = load_telescope()
    return t.create(results, default, { prompt_title = prompt_title })
end

function filetype.set_autocmds(self, autocmds)
    autocmds = autocmds or self.autocmds
    if not autocmds or is_empty(autocmds) then
        return
    end

    local out = {}
    each(autocmds, function(au_name, callback)
        au_name = self.name .. "." .. au_name
        out[au_name] = autocmd.map("FileType", { callback = callback, pattern = self.name, name = au_name })
    end)

    return out
end

function filetype.setup_lsp(self)
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

function filetype.load_config(self)
    local user_msg, msg, ok

    if req2path(self.config_require_path) then
        ok, msg = pcall(require, self.config_require_path)
    end

    if req2path(self.user_config_require_path) then
        ok, user_msg = logger.pcall(require, self.user_config_require_path)
    end

    filetype.set_autocmds(self, self.autocmds)
    filetype.set_mappings(self, self.mappings)
    filetype.add_filetype(self, self.filetype)

    return self
end

function filetype.autocmd(self, opts)
    opts = opts or {}
    opts = deepcopy(opts)
    opts.group = self.augroup
    opts.pattern = self.name

    return autocmd("FileType", opts)
end

function filetype.autocmds_with_opts(self, opts, autocmds)
    opts = deepcopy(opts)
    opts.group = self.augroup
    opts.event = "FileType"
    opts.pattern = self.name

    autocmds = deepcopy(autocmds)

    tmap(autocmds, function(_, au_spec)
        au_spec.name = "filetype." .. self.name .. "." .. au_spec.name
    end)

    autocmd.map_with_opts(opts, autocmds)
end

function filetype.map_with_opts(self, opts, mappings)
    opts = deepcopy(opts)
    opts.apply = function(mode, ks, cb, rest)
        rest.pattern = self.name
        rest.event = "FileType"
        rest.name = "filetype." .. self.name .. "." .. rest.name
        return mode, ks, cb, rest
    end
    kbd.map_with_opts(opts, mappings)
end

function filetype.map(self, mode, ks, cb, rest)
    if is_a.string(rest) then
        rest = { desc = rest }
    end
    rest = deepcopy(rest)
    rest.name = "filetype." .. self.name .. "." .. rest.name
    rest.event = "FileType"
    rest.pattern = self.name
    return kbd.map(mode, ks, cb, rest)
end

function filetype.set_mappings(self, mappings)
    mappings = mappings or self.mappings

    if not mappings or is_empty(self.mappings) then
        return
    end

    local out = {}
    local opts = mappings.opts

    teach(mappings, function(name, spec)
        if name == "opts" then
            return
        end

        if opts then
            local mode, ks, cb, rest
            ks, cb, rest = unpack(spec)
            rest = is_a.string(rest) and { desc = rest } or rest
            rest = merge(rest or {}, opts)
            rest.name = self.name .. "." .. name
            rest.event = "FileType"
            rest.pattern = self.name
            mode = rest.mode or "n"
            spec = { mode, ks, cb, rest }
            out[name] = apply(kbd.map, spec)
        else
            spec = deepcopy(spec)
            local mode, ks, cb, rest = unpack(spec)
            rest = is_a.string(rest) and { desc = rest } or rest
            rest = rest or {}
            rest.name = self.name .. "." .. name
            rest.event = "FileType"
            rest.pattern = self.name
            spec[4] = rest

            out[name] = apply(kbd.map, spec)
        end
    end)

    return out
end

function filetype.format_dir(self, p, opts)
    p = p or buffer.name()
    local exists = filetype.processes[p]

    if exists and job.is_active(exists) then
        local userint = vim.fn.input("stop job for " .. p .. " (y for yes) % ")
        if userint == "y" then
            job.stop(exists)
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

    if is_a.list(args) and not formatter_config_path_exists(self.formatter_local_config_path) then
        cmd = concat(cmd .. " " .. args, " ")
    end

    local append_dirname = opts.append_dirname

    if append_dirname then
        p = p:gsub("~", os.getenv "HOME")
        p = p:gsub("%$HOME", os.getenv "HOME")
        p = p:gsub("%$XDG_CONFIG", path.join(os.getenv "HOME", ".config"))
        cmd = cmd .. " " .. path.abspath(p)
    end

    local proc = job(cmd, {
        on_exit = function(j)
            local err = j.errors
            local out = j.lines

            if err then
                to_stderr(join(err, "\n"))
                return
            end

            if not out then
                vim.notify("successfully ran command " .. cmd)
                return
            else
                vim.notify("successfully ran command " .. cmd .. "\n" .. concat(j.stdout, "\n"))
            end
        end,
    })

    filetype.processes[p] = proc

    return proc
end

function filetype.format_buffer(self, bufnr, opts)
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

    if is_a.list(args) then
        cmd = cmd .. " " .. join(args, " ")
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
    local proc = job(cmd, {
        output = true,
        on_exit = function(x)
            if x.exit_code ~= 0 then
                return
            end

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

            local err = x.errors
            if #err > 0 then
                to_stderr(join(err, "\n"))
                return
            end

            local out = x.lines
            if not out then
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
    if exists and job.is_active(exists) then
        local userint = input {
            "userint",
            "Stop existing Process for " .. bufname .. "? (y for yes)",
        }

        if userint.userint:match "y" then
            job.stop(exists)
        end
    end

    filetype.processes[bufname] = proc

    return proc
end

function filetype.get(ft, attrib, callback)
    if is_number(ft) then
        ft = buffer.option(ft, "filetype")
    end

    local x = filetype(ft)

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

function filetype.load_defaults(ft)
    local p = "core.ft." .. ft
    if req2path(p) then
        return require(p)
    end
end

function filetype.load_spec(ft, is_user)
    local fname

    if is_user then
        fname = "user.ft." .. ft
    else
        fname = "core.ft." .. ft
    end

    if not req2path(fname) then
        return
    end

    local ok, msg = pcall(require, fname)
    local self = filetype.filetypes[ft] or filetype(ft)

    if ok then
        filetype.filetypes[self.name] = self
        filetype.load_config(self)
        filetype.load_config(self, true)
    else
        return false, msg
    end

    return ok, self
end

function filetype.add_filetype(self)
    if not self.filetype then
        return
    end

    vim.filetype.add(self.filetype)
    return true
end

function filetype.load_specs(is_user)
    local function name(f)
        return split(path.basename(f), "%.")[1]
    end

    if not is_user then
        each(dir.getallfiles(user.dir .. "/lua/core/ft/"), function(f)
            f = name(f)
            filetype.load_spec(f)
        end)
    else
        each(dir.getallfiles(user.user_dir .. "/lua/user/ft/"), function(f)
            filetype.load_spec(name(f), true)
        end)
    end
end

function filetype.load()
    return filetype.load_specs()
end

local function find_workspace(start_dir, pats, maxdepth, _depth)
    maxdepth = maxdepth or 5
    _depth = _depth or 0
    pats = to_list(pats or "%.git$")

    if maxdepth == _depth then
        return false
    end

    if not path.isdir(start_dir) then
        return false
    end

    local parent = path.dirname(start_dir)
    local children = dir.getfiles(start_dir)

    for i = 1, #pats do
        local pat = pats[i]

        for j = 1, #children do
            if children[j]:match(pat) then
                return children[j]
            end
        end
    end

    return find_workspace(parent, pats, maxdepth, _depth + 1)
end

local function find_buffer_workspace(bufnr, pats, maxdepth, _depth)
    bufnr = bufnr or buffer.bufnr()
    if is_string(bufnr) then
        bufnr = buffer.bufnr(bufnr)
    end

    if not buffer.exists(bufnr) then
        return false
    end


    local lspconfig = require "lspconfig"
    local server = filetype.get(buffer.option(bufnr, "filetype"), "lsp_server")

    assert_type(server, union('string', 'table'))

    local bufname = buffer.name(bufnr)
    local config = is_string(server) and lspconfig[server] or lspconfig[server[1]]
    local root_dir_checker = config.document_config.default_config.root_dir

    if not server then
        return find_workspace(bufname, pats, maxdepth, _depth)
    end

    if not config.get_root_dir then
        return find_workspace(bufname, pats, maxdepth, _depth)
    elseif root_dir_checker then
        return root_dir_checker(bufname)
    end

    return config.get_root_dir(bufname)
end

function filetype.workspace(p, pats, maxdepth, _depth)
    p = p or buffer.bufnr()
    return find_buffer_workspace(p, pats, maxdepth, _depth)
end

function filetype.attrib(self, attrib, callback)
    return filetype.if_exists(self, function(x)
        if callback then
            return callback(x[attrib])
        end

        return x[attrib]
    end)
end

function filetype.command(self, attrib)
    return filetype.attrib(self, attrib, function(config)
        if is_string(config) then
            config = {{config}}
        end

        if not config.cmd and not config[1] then
            return
        end

        local cmd = config.cmd or config[1]

        validate {
            command = {
                union('string', "table", "callable"),
                cmd,
            },
        }

        return function(bufname)
            bufname = bufname or buffer.name()


            if is_string(cmd) then
                return cmd
            end

            bufname = bufname or buffer.name()
            assert_type(cmd, union("function", "table"))

            if is_function(cmd) then
                return cmd(bufname)
            end

            local match = cmd.match
            local workspace = cmd.workspace
            local default = cmd[1]
            local buf_workspace = filetype.workspace(bufname)

            if workspace and buf_workspace then
                if buf_workspace then
                    path.chdir(buf_workspace)
                end

                if is_function(workspace) then
                    return workspace(buf_workspace, bufname)
                end

                return workspace, buf_workspace
            end

            if match then
                for key, value in pairs(match) do
                    if not bufname:match(key) then
                        break
                    end

                    if is_function(value) then
                        return value(key, bufname)
                    else
                        return value
                    end
                end
            end

            self = filetype.get_by_buf(bufname)
            if not default then
                error("no default command provided for " .. self.name)
            end

            return default
        end
    end)
end

--[[
compile = {
    {
        'luajit %s',
        workspace = 'luarocks --local build',
        match = {
            ...
        }
    }
}

compile = {
    'luajit %s',
}

--]]

local function get_compile_command(bufnr, action)
    bufnr = resolvebuf(bufnr)
    local bufname = buffer.name(bufnr)
    action = action or "compile"
    local cmd, ws
    cmd, ws = filetype.command(bufnr, action)

    if not cmd then
        return
    end

    cmd = cmd(bufname)

    if ws then
        return sprintf(cmd, ws)
    end

    return sprintf(cmd, bufname)
end

local function save_compile_command(dirname, cmd)
    local fname = system("mktemp")[1]
    local contents = {
        "#!/bin/bash",
        "",
        "cd " .. dirname,
        "exec " .. cmd,
        "",
    }

    file.write(fname, concat(contents, "\n"))
    return ("bash " .. fname), function()
        return file.delete(fname)
    end
end

function filetype.compile_buffer(bufnr, action, direction)
    action = action or 'compile'
    bufnr = resolvebuf(bufnr)
    local bufname = buffer.name(resolvebuf(bufnr))

    if bufname:match('%.config/nvim') then
        vim.cmd(':luafile ' .. bufname)
        return
    end

    local cmd = get_compile_command(bufnr, action)

    if not cmd then
        say(sprintf("%s: no command found for action %s", bufname, action))
        return
    end

    if ws then
        return job.oneshot(cmd, { float = true, cwd = ws })
    end

    return job.oneshot(cmd, { float = true, cwd = dirname })
end

function filetype.if_exists(ft, callback, failure)
    ft = resolve(ft)
    local exists = filetype.filetypes[ft]

    if not exists then
        if failure then
            return failure()
        end
        return
    end

    if callback then
        return callback(exists)
    end

    return exists
end
