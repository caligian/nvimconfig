say = vim.notify

require "core.globals"
require "core.option"
require "core.defaults"
require "core.netrw"

Filetype.load_specs()
Plugin.setup_lazy()
Plugin.load_config_dir()
Bookmark()

say = Plugin.get('notify').methods.say or vim.notify

if user.zenmode then vim.cmd ":EnableZenMod" end
