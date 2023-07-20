require "core.globals"
require "core.option"
require "core.defaults"
require "core.netrw"

Filetype.load_specs()

plugin.setup_lazy()

if user.zenmode then
    vim.cmd ":EnableZenMod"
end

font.set_default()
