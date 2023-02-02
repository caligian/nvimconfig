local req = 'core.pkg.configs.nvim-treesitter.defaults'
local user_req = 'user.pkg.configs.nvim-treesitter'

user.pkg['nvim-treesitter'] = builtin.require(req)
pcall(builtin.require, user_req)

builtin.require('nvim-treesitter.configs').setup(user.pkg['nvim-treesitter'])
