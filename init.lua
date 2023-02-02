require 'utils'
require 'utils.commands'

-- Add (c)path(s) for ~/.config/nvim/luarocks, ~/.nvim/lua
local config_dir = vim.fn.stdpath('config')
local home_dir = os.getenv('HOME') .. '/.nvim'
builtin.add_package_cpath(config_dir .. "/luarocks/share/lua/5.1/?.so")
builtin.add_package_cpath(config_dir .. "/luarocks/lib/lua/5.1/?.so")
builtin.add_package_path(config_dir .. "/luarocks/share/lua/5.1/?.lua")
builtin.add_package_path(config_dir .. "/luarocks/share/lua/5.1/?/?.lua")
builtin.add_package_path(config_dir .. "/luarocks/share/lua/5.1/?/init.lua")
builtin.add_package_path(home_dir .. "/lua/?.lua")
builtin.add_package_path(home_dir .. "/lua/init.lua")
builtin.add_package_path(home_dir .. "/lua/?/init.lua")

-- Require 'globals'
require 'logging.file'

builtin.global {
	class = require 'pl.class',
	yaml = require 'yaml',
	path = require 'pl.path',
	listcomp = require 'pl.comprehension',
	stringx = require 'pl.stringx',
	tablex = require 'pl.tablex',
	operator = require 'pl.operator',
	types = require 'pl.types',
    file = require 'pl.file',
    dir = require 'pl.dir',
	json = {encode=vim.json_encode, decode=vim.json_decode},
	user = {},
}

-- Load the framework
require 'core'
