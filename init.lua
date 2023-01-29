require 'core.utils'

-- To enable support for luarocks installed at ~/.config/nvim/luarocks
local config_dir = vim.fn.stdpath('config')
builtin.add_package_path(
config_dir .. '/luarocks/share/lua/5.1/?.lua',
config_dir .. '/luarocks/share/lua/5.1/?/init.lua',
config_dir .. '/luarocks/share/lua/5.1/?/?.lua')

builtin.add_package_cpath(
config_dir .. '/luarocks/share/lua/5.1/?.so',
config_dir .. '/luarocks/lib/lua/5.1/?.so')

-- ~/.nvim is the user configuration directory
-- ~/.nvim/lua/ is added to the path
-- You should put your configuration in ~/.nvim/lua/user as your configs can be required by require 'user.<...>'
builtin.add_package_path(
os.getenv('HOME') .. '.nvim/lua/init.lua',
os.getenv('HOME') .. '.nvim/lua/?/?.lua',
os.getenv('HOME') .. '.nvim/lua/?/init.lua')

-- These rocks are super important
-- lua-yaml, penlight, lualogging
local missing_rocks = builtin.require_rock('yaml', 'pl', 'logging')
if #missing_rocks > 0 then
    for _, rock in ipairs(missing_rocks) do
        builtin.nvim_err(sprintf('Luarock missing: %s', rock))
    end
    error(builtin.sprintf('Please download the missing rocks :%s', missing_rocks))
end

-- Make some global variables containing goodies
require 'logging.file'
require 'pl.class'

builtin.global {
	yaml = require 'yaml',
	path = require 'pl.path',
	listcomp = require 'pl.comprehension',
	str = require 'pl.stringx',
	seq = require 'pl.seq',
	tbl = require 'pl.tablex',
	operator = require 'pl.operator',
	types = require 'pl.types',
	json = {
		encode = vim.json_encode,
		decode = vim.json_decode,
	},
	logging = logging,
	logger = logging.file {filename = vim.fn.stdpath('config') .. '/nvim.log'},
	user = {},
}

-- Load the framework
require 'core'
