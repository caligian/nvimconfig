require "core.utils.buffer_group"

local home = os.getenv "HOME"

buffer_group.defaults = {
  event = "BufAdd",
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
  buffer_group.buffer.run_picker(buffer.bufnr())
end

buffer_group.mappings = {
  opts = { leader = true, noremap = true },
  buffer_picker = { ".", run_picker },
}

return function()
  buffer_group.load_defaults(buffer_group.defaults)
  buffer_group.set_autocmds(buffer_group.autocmds)
  buffer_group.set_mappings(buffer_group.mappings)
end
