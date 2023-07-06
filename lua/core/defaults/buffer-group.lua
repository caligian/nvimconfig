local home = os.getenv 'HOME'

buffer_group.defaults = {
    event = "BufEnter",
    nvim = user.dir,
    user_nvim = user.user_dir,
    plugins = user.data_dir,
    elixir = "exs?$",
    julia = "jl$",
    python = "py$",
    lua = "lua$",
    bash = { pattern = { "bash$", "sh$" } },
    ruby = { pattern = { "erb$", "rb$" } },
    scripts = home .. "/" .. "[Ss]cripts",
    work = {
        pattern = {
            home .. "/" .. "[wW]ork",
            home .. "/" .. "[dD]ocuments",
        },
    },
}

buffer_group.commands = {
    bufferPicker = {
        function(cmd)
            if is_a.number(cmd) then
                buffer_group.run_picker(cmd)
            else
                local args = cmd.fargs or {}
                local buf = args[1] or buffer.bufnr()
                buffer_group.run_picker(buf)
            end
        end,
        {
            complete = function()
                return buffer.list({ listed = true }, { name = true })
            end,
            map = { "n", "<leader>." },
            nargs = "?",
        },
    },
}

return function ()
    buffer_group.load_defaults()
    buffer_group.map_commands()
    buffer_group.load_mappings()
end
