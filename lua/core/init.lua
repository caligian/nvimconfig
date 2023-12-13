say = vim.notify

require "core.globals"
require "core.netrw"
require "core.option"

bookmark.main()
filetype.main()
repl.main()
buffergroup.main()
kbd.main()
au.main()
plugin.main()

require 'core.defaults.commands'
