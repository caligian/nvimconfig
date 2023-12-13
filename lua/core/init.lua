say = vim.notify

require "core.globals"
require "core.option"
require "core.defaults"
require "core.netrw"

bookmark.main()
filetype.main()
plugin.main()
repl.set_mappings()

-- say = plugin.get('notify').methods.say or vim.notify
