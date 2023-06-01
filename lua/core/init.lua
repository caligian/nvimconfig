require "core.globals"
require "core.option"
require "core.BufferGroup"
Filetype.loadall()

require "core.utils.Plugin"
require "core.defaults"
require "core.utils.Font"
require "core.bookmarks"
require "core.repl"
require "core.netrw"

Plugin.setup()
if user.zenmode then vim.cmd ":EnableZenMod" end

require 'core.utils.Font'
Font.loaduser()
