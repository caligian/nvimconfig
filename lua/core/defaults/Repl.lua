require "core.utils.Repl"
require "core.utils.Command"


local function get_repl(bufnr, callback, opts)
    opts = opts or {}
    bufnr = bufnr or buffer.bufnr()
    local repl = Repl.get(bufnr)
    local start = opts.start
    local running = opts.running
    local orelse = opts.orelse
    local message = opts.message

    if start then
        repl = repl or Repl(bufnr)

        if Repl.is_running(repl) then
            if repl.connected then
                say("Repl is already running: " .. tostring(repl))
            else
                say("Filetype Repl is already running: " .. tostring(repl))
            end

            if callback then
                callback(repl)
            end

            return
        else
            Repl.start(repl)
        end

        if message and repl then
            message(repl)
        end

        return
    end

    if running then
        if repl and Repl.is_running(repl) then
            callback(repl)
        elseif orelse then
            orelse(bufnr)
        end
    elseif repl then
        callback(repl)
    elseif orelse then
        orelse(bufnr)
    end

    if message and repl then
        message(repl)
    end
end

local function create_mod(opts)
    local buf = opts.buffer
    local ft = opts.ft

    return setmetatable({}, {
        __newindex = function(self, key, value)
            rawset(self, key, function(...)
                local args = { ... }

                if key == "start" then
                    if buf then
                        local bufnr = buffer.bufnr()
                        get_repl(bufnr, value, {
                            start = true,
                            running = true,
                            message = function(repl)
                                say(sprintf("Repl started for buffer %d\n%s", bufnr, tostring(repl)))
                            end,
                        })
                    elseif ft then
                        ft = args[1] or buffer.option(buffer.bufnr(), "filetype")

                        if not Filetype.get(ft, "repl") then
                            say("No Repl command exists for filetype " .. ft)
                            return
                        end

                        get_repl(ft, value, {
                            start = true,
                            running = true,
                            message = function(repl)
                                say(sprintf("Repl started for filetype %s\n%s", ft, tostring(repl)))
                            end,
                        })
                    end
                elseif ft then
                    ft = args[1] or buffer.option(buffer.bufnr(), "filetype")

                    if not Filetype.get(ft, "repl") then
                        say("No Repl command exists for filetype " .. ft)
                        return
                    end

                    get_repl(ft, value, {
                        running = true,
                        orelse = function()
                            local msg = sprintf("No filetype repl running for %s. Run :ReplFtStart %s first", ft, ft)
                            say(msg)
                        end,
                    })
                elseif buf then
                    local bufnr = buffer.bufnr()
                    local ft = buffer.option(bufnr, "filetype")

                    if not Filetype.get(ft, "repl") then
                        say("No Repl command exists for filetype " .. ft)
                        return
                    end

                    get_repl(bufnr, value, {
                        running = true,
                        orelse = function()
                            say(sprintf("No Repl running for buffer %d [%s]. Run :ReplBufferStart %s first", bufnr, ft, ft))
                        end,
                    })
                end
            end)
        end,
    })
end

local buffer_mod = create_mod { buffer = true }
local ft_mod = create_mod { ft = true }
local sh_mod = create_mod { ft = "sh" }
local funs = {
    "send_current_line",
    "send_buffer",
    "send_till_cursor",
    "send_textsubject_at_cursor",
    "send_node_at_cursor",
    "send_range",
    "start",
    "stop",
    "split",
    "hide",
    "center_float",
    "dock",
    "tabnew",
    "vsplit",
    "botright",
    "belowright",
    "rightbelow",
    "leftabove",
    "aboveleft",
}

array.each(funs, function(fun)
    buffer_mod[fun] = Repl[fun]
    ft_mod[fun] = Repl[fun]
    sh_mod[fun] = Repl[fun]
end)

local function to_camelcase(name)
    name = string.split(name, "_")
    name = array.map(name, function(x)
        return string.gsub(x, "^([a-z])", string.upper)
    end)

    return array.join(name, "")
end

local function wrap_command(tp, callback)
    return function(args)
        local arg = args.fargs[1]

        if not arg then
            if tp == "b" then
                arg = tostring(buffer.bufnr())
            elseif tp == "f" then
                arg = buffer.option(buffer.bufnr(), "filetype")
            else
                arg = "sh"
            end
        elseif string.is_number(arg) then
            arg = tonumber(arg)
        end

        return callback(arg)
    end
end

local commands = {}
array.each(keys(buffer_mod), function(fun)
    local buf_name = to_camelcase("repl_buffer_" .. fun)
    local ft_name = to_camelcase("repl_ft_" .. fun)
    local sh_name = to_camelcase("repl_sh_" .. fun)
    commands[buf_name] = Command(buf_name, wrap_command("b", buffer_mod[fun]), { nargs = "?" })
    commands[ft_name] = Command(ft_name, wrap_command("f", ft_mod[fun]), { nargs = "?" })
    commands[sh_name] = Command(sh_name, wrap_command("sh", sh_mod[fun]), { nargs = "?" })
end)

local mappings = { opts = { noremap = true } }
local cmds = {
    r = "start",
    q = "stop",
    k = "hide",
    s = "split",
    v = "vsplit",
    t = "tabnew",
    d = "dock",
    f = "center_float",
    e = "send_current_line",
    [">"] = "send_till_cursor",
    ["."] = "send_node_at_cursor",
    ["b"] = "send_buffer",
    [";"] = "send_textsubject_at_cursor",
}

dict.each(cmds, function(key, fun)
    mappings["buffer_" .. fun] = { "<leader>r" .. key, "<cmd>" .. to_camelcase("repl_buffer_" .. fun) .. "<cr>" }
    mappings["ft_" .. fun] = { "<localleader>r" .. key, "<cmd>" .. to_camelcase("repl_ft_" .. fun) .. "<cr>" }
    mappings["sh_" .. fun] =
        { "<leader>x" .. (key == "r" and "x" or key), "<cmd>" .. to_camelcase("repl_sh_" .. fun) .. "<Cr>" }
end) 

mappings["buffer_send_range"] = { "<leader>re", "<esc>:ReplBufferSendRange<CR>", { mode = "v" } }
mappings["ft_send_range"] = { "<localleader>re", "<esc>:ReplFtSendRange<CR>", { mode = "v" } }
mappings["sh_send_range"] = { "<leader>xe", "<esc>:ReplShSendRange<CR>", { mode = "v" } }
mappings['stop_all'] = {'<leader>rQ', ':lua Repl.stop_all()<CR>'}

Repl.commands = commands
Repl.mappings = kbd.map_group('Repl', mappings, true)

return function()
    Repl.load_commands(Repl.commands)
    Repl.load_autocmds(Repl.autocmds)
    Repl.load_mappings(Repl.mappings)
end
