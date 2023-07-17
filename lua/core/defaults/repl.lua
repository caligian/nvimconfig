require "core.utils.repl"

--------------------------------------------------
local function parse_args(args)
    return array.map(vim.split(args.args, " +"), function(x)
        if x:match "^[0-9]+%.?[0-9]*$" then
            x = tonumber(x)
        end
        return x
    end)
end

local function with_args(opts, callback)
    local args

    if is_a.table(opts) then
        args = parse_args(opts)
    elseif is_a.number(opts) then
        args = { opts }
    else
        args = { buffer.bufnr() }
    end

    callback(args)
end

repl.commands = {
    send = {
        function(opts)
            with_args(opts, function(args)
                local x = repl.new(args[1])
                if not x then
                    return
                end

                assert(args[2] ~= nil, "no string given")

                x:send(args[2])
            end)
        end,
        { nargs = "?" },
    },
    sendBuffer = {
        function(opts)
            with_args(opts, function(args)
                local x = repl.new(args[1])
                if not x then
                    return
                end

                if is_a.number(args[1]) then
                    x:send_buffer(args[1])
                else
                    x:send_buffer(buffer.bufnr())
                end
            end)
        end,
        { nargs = "?" },
    },
    sendRange = {
        function(opts)
            with_args(opts, function(args)
                local x = repl.new(args[1])
                if not x then
                    return
                end

                if is_a.number(args[1]) then
                    x:send_range(args[1])
                else
                    x:send_range(buffer.bufnr())
                end
            end)
        end,
        { nargs = "?" },
    },
    sendLine = {
        function(opts)
            with_args(opts, function(args)
                local x = repl.new(args[1])
                if not x then
                    return
                end

                local s
                local bufnr = buffer.bufnr()
                if not args[2] then
                    if is_a.number(args[1]) then
                        bufnr = args[1]
                        assert(buffer.exists(bufnr), "invalid_buffer")
                    end

                    s = buffer.pos(bufnr)
                    s = buffer.lines(bufnr, s.row - 1, s.row)
                end

                x:send(s)
            end)
        end,
        { nargs = "?" },
    },
    start = {
        function(opts)
            with_args(opts, function(args)
                local x = repl.new(unpack(args))
                if x then
                    x:split "s"
                end
            end)
        end,
        { nargs = "?" },
    },
    stop = {
        function(opts)
            with_args(opts, function(args)
                repl.stop(unpack(args))
            end)
        end,
        { nargs = "?" },
    },
    centerFloat = {
        function(opts)
            with_args(opts, function(args)
                local x = repl.new(args[1])
                local bufnr = x.bufnr
                if args[2] then
                    x:center_float {center = {args[2], args[2]}, relative='editor'}   
                else
                    x:center_float {center = {0.8, 0.8}, relative='editor'}   
                end
            end)
        end,
        { nargs = "?" },
    },
    float = {
        function(opts)
            with_args(opts, function(args)
                local x = repl.new(args[1])
                local bufnr = x.bufnr
                if args[2] then
                    x:center_float {center = {args[2], args[2]}, relative='win'}   
                else
                    x:center_float {center = {0.8, 0.8}, relative='win'}   
                end
            end)
        end,
        { nargs = "?" },
    },
    dock = {
        function(opts)
            with_args(opts, function(args)
                local x = repl.new(args[1])
                x:dock { dock = args[2] or 0.3 }
            end)
        end,
        { nargs = "?" },
    },
    hide = {
        function(opts)
            with_args(opts, function(args)
                local x = repl.new(unpack(args))
                x:hide()
            end)
        end,
        { nargs = "?" },
    },
    vsplit = {
        function(opts)
            with_args(opts, function(args)
                local x = repl.new(unpack(args))
                x:split "v"
            end)
        end,
        { nargs = "?" },
    },
    botright = {
        function(opts)
            with_args(opts, function(args)
                local x = repl.new(unpack(args))
                x:split "botright"
            end)
        end,
        {
            nargs = "?",
        },
    },
    topleft = {
        function(opts)
            with_args(opts, function(args)
                local x = repl.new(unpack(args))
                x:split "topleft"
            end)
        end,
        {
            nargs = "?",
        },
    },
    aboveleft = {
        function(opts)
            with_args(opts, function(args)
                local x = repl.new(unpack(args))
                x:split "aboveleft"
            end)
        end,
        {
            nargs = "?",
        },
    },
    belowright = {
        function(opts)
            with_args(opts, function(args)
                local x = repl.new(unpack(args))
                x:split "belowright"
            end)
        end,
        {
            nargs = "?",
        },
    },
    rightbelow = {
        function(opts)
            with_args(opts, function(args)
                local x = repl.new(unpack(args))
                x:split "belowright"
            end)
        end,
        {
            nargs = "?",
        },
    },
    tabnew = {
        function(opts)
            with_args(opts, function(args)
                local x = repl.new(unpack(args))
                x:split "t"
            end)
        end,
        {
            nargs = "?",
        },
    },
    leftabove = {
        function(opts)
            with_args(opts, function(args)
                local x = repl.new(unpack(args))
                x:split "aboveleft"
            end)
        end,
        {
            nargs = "?",
        },
    },
    split = {
        function(opts)
            with_args(opts, function(args)
                local x = repl.new(unpack(args))
                x:split "s"
            end)
        end,
        {
            nargs = "?",
        },
    },
}

--------------------------------------------------

repl.mappings = {
    opts = { noremap = true, silent = true },
    buffer_send_range = {
        "<leader>re",
        ':<C-U>call execute("ReplSendRange " . bufnr())<CR>',
        { desc = "send range", mode = "v" },
    },
    buffer_send_line = {
        "<leader>re",
        function()
            vim.cmd(":ReplSendLine " .. buffer.bufnr())
        end,
        { desc = "send range (visual)" },
    },
    buffer_send_buffer = {
        "<leader>rb",
        function()
            vim.cmd(":ReplSendBuffer " .. buffer.bufnr())
        end,
        { desc = "send buffer" },
    },
    buffer_start = {
        "<leader>rr",
        function()
            vim.cmd(":ReplStart " .. buffer.bufnr())
        end,
        { desc = "start" },
    },
    buffer_hide = {
        "<leader>rk",
        function()
            vim.cmd(":ReplHide " .. buffer.bufnr())
        end,
        { desc = "hide" },
    },
    buffer_stop = {
        "<leader>rq",
        function()
            vim.cmd(":ReplStop " .. buffer.bufnr())
        end,
        { desc = "stop" },
    },
    buffer_vsplit = {
        "<leader>rv",
        function()
            vim.cmd(":ReplVsplit " .. buffer.bufnr())
        end,
        { desc = "vsplit" },
    },
    buffer_split = {
        "<leader>rs",
        function()
            vim.cmd(":ReplSplit " .. buffer.bufnr())
        end,
        { desc = "split" },
    },
    buffer_dock = {
        "<leader>rd",
        function()
            vim.cmd(":ReplSplit " .. buffer.bufnr())
        end,
        { desc = "dock" },
    },
    buffer_center_float = {
        "<leader>rF",
        function()
            vim.cmd(":ReplCenterFloat " .. buffer.bufnr())
        end,
        { desc = "float in middle" },
    },
    buffer_float = {
        "<leader>rf",
        function()
            vim.cmd(":ReplCenterFloat " .. buffer.bufnr())
        end,
        { desc = "float in middle of buffer" },
    },
    filetype_send_range = {
        "<localleader>re",
        ':<C-U>call execute("ReplSendRange " . &filetype)<CR>',
        { desc = "send range", mode = "v" },
    },
    filetype_send_line = {
        "<localleader>re",
        function()
            vim.cmd(":ReplSendLine " .. buffer.option(buffer.bufnr(), "filetype"))
        end,
        { desc = "send range (visual)" },
    },
    filetype_send_buffer = {
        "<localleader>rb",
        function()
            vim.cmd(":ReplSendBuffer " .. buffer.option(buffer.bufnr(), "filetype"))
        end,
        { desc = "send buffer" },
    },
    filetype_start = {
        "<localleader>rr",
        function()
            vim.cmd(":ReplStart " .. buffer.option(buffer.bufnr(), "filetype"))
        end,
        { desc = "start" },
    },
    filetype_hide = {
        "<localleader>rk",
        function()
            vim.cmd(":ReplHide " .. buffer.option(buffer.bufnr(), "filetype"))
        end,
        { desc = "hide" },
    },
    filetype_stop = {
        "<localleader>rq",
        function()
            vim.cmd(":ReplStop " .. buffer.option(buffer.bufnr(), "filetype"))
        end,
        { desc = "stop" },
    },
    filetype_vsplit = {
        "<localleader>rv",
        function()
            vim.cmd(":ReplVsplit " .. buffer.option(buffer.bufnr(), "filetype"))
        end,
        { desc = "vsplit" },
    },
    filetype_split = {
        "<localleader>rs",
        function()
            vim.cmd(":ReplSplit " .. buffer.option(buffer.bufnr(), "filetype"))
        end,
        { desc = "split" },
    },
    filetype_dock = {
        "<localleader>rd",
        function()
            vim.cmd(":ReplSplit " .. buffer.option(buffer.bufnr(), "filetype"))
        end,
        { desc = "dock" },
    },
    filetype_center_float = {
        "<localleader>rF",
        function()
            vim.cmd(":ReplCenterFloat " .. buffer.option(buffer.bufnr(), "filetype"))
        end,
        { desc = "float in middle" },
    },
    filetype_float = {
        "<localleader>rf",
        function()
            vim.cmd(":ReplCenterFloat " .. buffer.option(buffer.bufnr(), "filetype"))
        end,
        { desc = "float in middle of buffer" },
    },
    shell_send_range = {
        "<leader>xe",
        ':<C-U>call execute("ReplSendRange " . "sh")<CR>',
        { desc = "send range", mode = "v" },
    },
    shell_send_line = {
        "<leader>xe",
        function()
            vim.cmd(":ReplSendLine " .. "sh")
        end,
        { desc = "send range (visual)" },
    },
    shell_send_buffer = {
        "<leader>xb",
        function()
            vim.cmd(":ReplSendBuffer " .. "sh")
        end,
        { desc = "send buffer" },
    },
    shell_start = {
        "<leader>xx",
        function()
            vim.cmd(":ReplStart " .. "sh")
        end,
        { desc = "start" },
    },
    shell_hide = {
        "<leader>xk",
        function()
            vim.cmd(":ReplHide " .. "sh")
        end,
        { desc = "hide" },
    },
    shell_stop = {
        "<leader>xq",
        function()
            vim.cmd(":ReplStop " .. "sh")
        end,
        { desc = "stop" },
    },
    shell_vsplit = {
        "<leader>xv",
        function()
            vim.cmd(":ReplVsplit " .. "sh")
        end,
        { desc = "vsplit" },
    },
    shell_split = {
        "<leader>xs",
        function()
            vim.cmd(":ReplSplit " .. "sh")
        end,
        { desc = "split" },
    },
    shell_dock = {
        "<leader>xd",
        function()
            vim.cmd(":ReplSplit " .. "sh")
        end,
        { desc = "dock" },
    },
    shell_center_float = {
        "<leader>xF",
        function()
            vim.cmd(":ReplCenterFloat " .. "sh")
        end,
        { desc = "float in middle" },
    },
    shell_float = {
        "<leader>xf",
        function()
            vim.cmd(":ReplCenterFloat " .. "sh")
        end,
        { desc = "float in middle of buffer" },
    },
    stop_all = {
        "<leader>rQ",
        repl.stop_all,
        { desc = "stop all" },
    },
}

repl.autocmds = {
    stop_all = {
        "QuitPre",
        { callback = repl.stop_all, pattern = "*" },
    },
}

return function()
    repl.map_commands()
    repl.load_mappings()
    repl.load_autocmds()
end
