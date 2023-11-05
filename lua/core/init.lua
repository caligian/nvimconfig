say = vim.notify

require "core.globals"
require "core.option"
require "core.defaults"
require "core.netrw"

bookmark.load()
filetype.load_specs()
plugin.load()

-- say = plugin.get('notify').methods.say or vim.notify
