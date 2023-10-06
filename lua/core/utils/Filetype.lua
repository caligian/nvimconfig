require "core.utils.autocmd"
require "core.utils.kbd"
require "core.utils.lsp"
require "lua-utils.class"
require "core.utils.Process"

local add_ft = vim.filetype.add

Filetype = Filetype
    or struct.new("Filetype", {
        'actions',
        'abbrevs',
        "name",
        'filetype',
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

-- Filetype.filetypes = Filetype.filetypes or {}
Filetype.filetypes = Filetype.filetypes or {}
Filetype.id = #Filetype.filetypes or 1
Filetype.processes = Filetype.processes or {}

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

    Filetype.filetypes[self.name] = self

    return self
end

-- run when in a workspace
function Filetype.create_actions_picker(bufnr)
    bufnr = bufnr or buffer.bufnr()
    local ft = buffer.option(bufnr, 'filetype')
    local specs = Filetype.get(ft, 'actions')
    local p = buffer.name(bufnr)
    local workspace

    if not specs or is_empty(specs) then
        return false
    else
        specs = vim.deepcopy(specs)
    end

    workspace = Filetype.workspace(bufnr)
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
        error('no default action provided')
    end

    local results = {
        results = keys(specs),
        entry_maker = function (x)
            if workspace then
                return {
                    value = x,
                    ordinal = x,
                    display = sprintf('(%s) %s', workspace, x),
                    workspace = workspace,
                }
            end

            return {
                value = x,
                ordinal = x,
                display = x,
            }

        end
    }

    local prompt_title
    do
        if not in_workspace then
            prompt_title = 'actions for ' .. p
        else
            prompt_title = 'actions for (workspace) ' .. workspace
        end
    end

    local t = load_telescope()
    return t.create(results, default, {prompt_title=prompt_title})
end

function Filetype.load_autocmds(self, autocmds)
    autocmds = autocmds or self.autocmds
    if not autocmds or is_empty(autocmds) then
        return
    end

    local out = {}
    dict.each(autocmds, function(au_name, callback)
        au_name = self.name .. "." .. au_name
        out[au_name] = autocmd.map("FileType", { callback = callback, pattern = self.name, name = au_name })
    end)

    return out
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

function Filetype.load_config(self)
    local msg = require(self.config_require_path)
    local user_msg

    if req2path(self.user_config_require_path) then
        user_msg = logger.pcall(require, self.user_config_require_path)
    end

    if msg and user_msg then
        merge(msg, user_msg)
    end

    Filetype.load_autocmds(msg, msg.autocmds)
    Filetype.load_mappings(msg, msg.mappings)
    Filetype.add_filetype(msg, msg.filetype)
    Filetype.load_abbrevs(msg, msg.abbrevs)

    return msg
end

function Filetype.load_abbrevs(self, spec)
    spec = spec or self.abbrevs or {}
    if is_empty(spec) then return end

    return Abbrev.map_dict({event = 'FileType', pattern = self.name}, spec)
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

    if not mappings or is_empty(self.mappings) then
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

function Filetype.format_dir(self, p, opts)
    local exists = Filetype.processes[p]
    if exists and Process.is_running(exists) then
        local userint = vim.fn.input("stop Process for " .. p .. " (y for yes) % ")
        if userint == "y" then
            Process.stop(exists)
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

    local proc = Process(cmd, {
        on_exit = function(j)
            pp(j)
            local err = j.stderr
            local out = j.stdout

            if err then
                to_stderr(array.join(err, "\n"))
                return
            end

            if not out then
                vim.notify("successfully ran command " .. cmd)
                return
            else
                vim.notify("successfully ran command " .. cmd .. "\n" .. array.join(j.stdout, "\n"))
            end
        end,
    })

    Process.start(proc)
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
    local proc = Process(cmd, {
        on_stdout = true,
        on_stderr = true,
        on_exit = function(x)
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

            local err = x.stderr
            if err then
                to_stderr(array.join(err, "\n"))
                return
            end

            local out = x.stdout
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

    local exists = Filetype.processes[bufname]
    if exists and Process.is_running(exists) then
        local userint = input {
            "userint",
            "Stop existing Process for " .. bufname .. "? (y for yes)",
        }
        if userint.userint:match "y" then
            Process.stop(exists)
        end
    end

    Filetype.processes[bufname] = proc
    Process.start(proc)

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
    if req2path(p) then
        return require(p)
    end
end

function Filetype.load_spec(ft_or_fname, is_user)
    local ft, fname
    if string.match(ft_or_fname, '%.lua$') then
        ft = string.gsub(path.basename(ft_or_fname), '%.lua$', '')
    else
        ft = ft_or_fname
    end

    if is_user then
        fname = 'user.ft.' .. ft
    else
        fname = 'core.ft.' .. ft
    end

    if not path.exists(req2path(fname)) then return end
    local ok, msg = pcall(require, fname)

    if ok then
        Filetype.filetypes[msg.name] = msg
        Filetype.load_config(msg)
        Filetype.load_config(msg, true)
    else
        return false, msg
    end

    return ok, msg
end

function Filetype.add_filetype(self)
    if not self.filetype then
        return
    end

    vim.filetype.add(self.filetype)
    return true
end

function Filetype.load_specs(is_user)
    if not is_user then
        array.each(dir.getallfiles(user.dir .. "/lua/core/ft/"), function(f)
            Filetype.load_spec(f)
        end)
    else
        array.each(dir.getallfiles(user.user_dir .. "/lua/user/ft/"), function(f)
            Filetype.load_spec(f, true)
        end)
    end
end

local function get_command(bufnr, action)
    bufnr = buffer.bufnr()
    local name = buffer.name(bufnr)
    local ft = buffer.option(bufnr, 'filetype')

    if #ft == 0 then
        return false
    end

    return Filetype.get(ft, action, function (config)
        local append_filename = true
        local cmd

        if is_string(config) then
            cmd = config
        elseif is_function(config) then
            cmd = config({bufnr = bufnr, bufname = name})
        elseif is_table(config) then
            config = copy(config)
            append_filename = dict.delete(config, {'append_filename'})

            for regex, cmd in pairs(t) do
                if string.match(name, regex) then
                    opts.cmd = cmd
                    break
                end
            end
        end

        if append_filename then
            cmd = cmd .. ' ' .. name
        elseif string.match(cmd, '%$bufname') then
            cmd = string.gsub(cmd, '%$bufname', name)
        end

        return cmd
    end)
end

local function clear_qflist()
    vim.fn.setqflist({})
end

local function to_qflist(src_bufnr, out)
    clear_qflist()

    out = array.grep(out, function (x) return #x ~= 0 end)
    out = array.map(out, function(x) return {bufnr = src_bufnr, text = x} end)

    vim.fn.setqflist(out)
end

function Filetype.run_command(cmd, out_bufname, direction)
    direction = direction or 's'
    local out_bufnr = buffer.bufadd(out_bufname)

    buffer.set_lines(out_bufnr, 0, -1, {})
    buffer.map(out_bufnr, 'in', 'q', ':bwipeout!<CR>', {desc = 'kill buffer'})
    buffer.autocmd(out_bufnr, 'BufDelete', function () buffer.wipeout(out_bufnr) end)
    buffer.set_option(out_bufnr, 'buftype', 'nofile')
    buffer.set_option(out_bufnr, 'buflisted', false)

    local opts =  {}
    opts.on_stdout = true 
    opts.on_stderr = true 

    opts.on_exit = function (job)
        if job.stdout then
            local out = copy(job.stdout)
            array.unshift(out, "-- STDOUT --")
            buffer.set_lines(out_bufnr, 0, -1, out)
        end

        if job.stderr then
            local out = copy(job.stderr)
            array.unshift(out, "-- STDERR --")
            buffer.set_lines(out_bufnr, -1, -1, out)
        end

        local s = buffer.string(out_bufnr)
        if s ~= "" then
            buffer.split(out_bufnr, 's')
            vim.cmd('resize 10')
        end

        print('recently ran command: ' .. cmd)
    end

    local proc = Process(cmd, opts)
    Process.start(proc)

    return proc
end

function Filetype.compile_buffer(bufnr, action, direction)
    bufnr = bufnr or buffer.current()
    action = action or 'compile'
    local cmd = Filetype.get(buffer.option(bufnr, 'filetype'), action)
    local bufname = buffer.name(bufnr)

    if not cmd then
        say(sprintf('%s: no command found for action %s', bufname, action))
        return
    elseif is_table(cmd) then
        for key, value in pairs(cmd) do
            if string.match(bufname, key) then
                cmd = value
                break
            end
        end

        assert(cmd, 'no command found for buffer ' .. bufname)
    elseif is_callable(cmd) then
        assert(cmd(bufname), 'no command found for buffer ' .. bufname)
    end

    local out_buffer = 'compile_output'
    if string.match(cmd, '%%s') then
        cmd = string.gsub(cmd, '%%s', bufname)
    else
        cmd = cmd .. ' ' .. bufname
    end

    Filetype.run_command(cmd, out_buffer, direction)
end

function Filetype.run_buffer(bufnr, cmd, direction)
    bufnr = bufnr or buffer.current()
    local bufname = buffer.name(bufnr)
    local out_bufname = cmd .. '_cmd_output'

    if buffer.exists(out_bufname) then
        buffer.wipeout(bufnr)
    end

    if string.match(cmd, '%s') then
        cmd = string.gsub(cmd, '%s', bufname)
    else
        cmd = cmd .. ' ' .. bufname
    end

    Filetype.run_command(cmd, out_bufname, direction)
end

function Filetype.load()
    return Filetype.load_specs()
end

local function find_workspace(start_dir, pats, maxdepth, _depth)
    max_depth = max_depth or 2
    _depth = _depth or 0
    pats = array.to_array(pats or "%.git$")

    if max_depth == _depth then
        return false
    end

    if not path.isdir(start_dir) then
        return false
    end

    start_dir = path.abspath(start_dir) 
    local parent = path.dirname(start_dir)
    local children = dir.getfiles(start_dir)

    for i=1, #pats do
        local pat = pats[i]

        for j=1,#children do
            if children[j]:match(pat) then
                return children[j]
            end
        end
    end

    return find_workspace(parent, pats, maxdepth, _depth+1)
end

local function find_buffer_workspace(bufnr, pats, maxdepth, _depth)
    bufnr = bufnr or buffer.bufnr()

    if not buffer.exists(bufnr) then
        return false
    end

    local lspconfig = require 'lspconfig'
    local server = Filetype.get(buffer.option(bufnr, 'filetype'), 'lsp_server')
    local bufname = buffer.name(bufnr)

    if not server then
        return find_workspace(bufname, pats, maxdepth, _depth)
    end

    local config = lspconfig[server[1]]
    if not config.get_root_dir then
        return find_workspace(bufname, pats, maxdepth, _depth)
    end

    return config.get_root_dir(bufname)
end

function Filetype.workspace(p, pats, maxdepth, _depth)
    p = p or buffer.bufnr()

    if is_number(p) then
        return find_buffer_workspace(p, pats, maxdepth, _depth)
    end

    return find_workspace(p, pats, maxdepth, _depth)
end
