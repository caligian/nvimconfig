say = vim.notify

require "core.globals"
require "core.option"
require "core.defaults"
require "core.netrw"


Filetype.load()
Plugin.load()
Bookmark.init()

say = Plugin.get('notify').methods.say or vim.notify
