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

local function run_picker()
    BufferGroup.buffer.run_picker(buffer.bufnr())
end

BufferGroup.mappings = {
    opts = {leader=true, noremap=true},
    buffer_picker = {'.', run_picker}
}

return function ()
    BufferGroup.load_defaults(BufferGroup.defaults)
    BufferGroup.set_autocmds(BufferGroup.autocmds)
    BufferGroup.set_mappings(BufferGroup.mappings)
end
