require "core.globals"
require "core.netrw"
require "core.option"

filetype.main()
bookmark.main()
repl.main()
buffergroup.main()
kbd.main()
au.main()
plugin.main()

plugin.plugins.colorscheme:setup()
plugin.plugins.indentblankline:setup()
plugin.plugins.statusline:setup()

require 'core.defaults.commands'
