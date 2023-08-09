require 'core.utils.BufferGroup'
local home = os.getenv "HOME"

BufferGroup.defaults = {
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

BufferGroup.commands = {
    BufferPicker = {
        function(cmd)
            local args = cmd.fargs
            args = args[1] and args[1] or buffer.bufnr()
            BufferGroup.buffer.run_picker(args)
        end,
        {
            complete = function()
                return buffer.list({ listed = true }, { name = true })
            end,
            nargs = "?",
        },
    },
}

BufferGroup.mappings = {
    opts = {leader=true, noremap=true},
    buffer_picker = {'.', '<cmd>BufferGroupBufferPicker<CR>'}
}

return function ()
    BufferGroup.load_defaults(BufferGroup.defaults)
    BufferGroup.load_autocmds(BufferGroup.autocmds)
    BufferGroup.load_mappings(BufferGroup.mappings)
    BufferGroup.load_commands(BufferGroup.commands)
end
