require "core.globals"
require "core.option"
-- require "core.BufferGroup"
require "core.defaults"
-- require "core.bookmarks"
require "core.netrw"

filetype.load_specs()
plugin.setup_lazy()

if user.zenmode then vim.cmd ":EnableZenMod" end

require "core.formatter"

--
font.set_default()
