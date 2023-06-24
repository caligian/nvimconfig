require "core.globals"
require "core.option"
require "core.BufferGroup"
require "core.defaults"
require "core.bookmarks"
require "core.netrw"

Plugin.setup()
if user.zenmode then vim.cmd ":EnableZenMod" end

require "core.formatter"

--
font.set_default()

-- Apply all user mappings
dict.each(user.mappings, function (_, obj) kbd.map(unpack(obj)) end)
