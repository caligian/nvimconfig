local defaults = require 'core.pkg.configs.nvim-treesitter.defaults'
user.pkg['nvim-treesitter'] = defaults

require 'user.pkg.configs.nvim-treesitter.defaults'

require('nvim-treesitter.configs').setup(user.pkg['nvim-treesitter'])
