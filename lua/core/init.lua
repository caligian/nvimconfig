-- These are extremely important
require 'core.utils'
local fennel = require 'core.fennel-utils'

-- Now fnl files in ~/.config/nvim/lua/ are visible
fennel.set_paths()

-- Require other stuff
require 'core.globals'; user.fennel = fennel
require 'core.option'
user.require 'core.autocmd'
user.require 'core.kbd'
user.require 'core.pkg'
user.require 'core.repl'
user.require 'core.kbd.defaults'
user.require 'core.repl.keybindings'
user.require 'core.repl.autocmds'
user.require 'core.autocmd.defaults'
