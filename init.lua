-- To enable support for luarocks installed at ~/.config/nvim/luarocks
local config_dir = vim.fn.stdpath('config')
package.path = package.path .. ';' .. config_dir .. '/luarocks/share/lua/5.1/?.lua'
package.path = package.path .. ';' .. config_dir .. '/luarocks/share/lua/5.1/?/init.lua'
package.path = package.path .. ';' .. config_dir .. '/luarocks/share/lua/5.1/?/?.lua'
package.cpath = package.cpath .. ';' .. config_dir .. '/luarocks/share/lua/5.1/?.so'
package.cpath = package.cpath .. ';' .. config_dir .. '/luarocks/lib/lua/5.1/?.so'

-- ~/.nvim is the user configuration directory
-- ~/.nvim/lua is added to the path
-- You should put your configuration in ~/.nvim/lua/user as your configs can be required by require 'user.<...>'
package.path = package.path .. ';' .. os.getenv('HOME') .. '/.nvim/lua/?/init.lua'

-- Check if all the luarocks are present are not
local missing_rocks = {}
function assert_rock(name, req_string)
    if not pcall(require, req_string) then
        vim.api.nvim_err_writeln(string.format('Luarock not installed: %s', name))
        missing_rocks[#missing_rocks+1] = name
    end
end

assert_rock('lua-yaml', 'yaml')
assert_rock('penlight', 'pl')
assert_rock('lualogging', 'logging')

if #missing_rocks > 0 then
    error {desc='Missing luarock', packages=missing_rocks, required='Use ~/.config/nvim/scripts/setup.sh' }
end

-- Make some global variables containing goodies
yaml = require 'yaml'
require 'logging.file'
path = require 'pl.path'
class = require 'pl.class'
C = require 'pl.comprehension'
str = require 'pl.stringx'
set = require 'pl.Set'
dir = require 'pl.dir'
file = require 'pl.file'
operator = require 'pl.operator'
seq = require 'pl.seq'
types = require 'pl.types'

-- User files are located in ~/.nvim/lua/
-- They should be present under ~/.nvim/lua/user as they will be called with string 'user.<...>' 
-- If a user file is present for the same system file (that is, same directory structure), the user file will be required but the output will be ignored
function require_user(req)
    local ok, out = pcall(require, 'user.' .. req)
    if not ok then
        return false
    else
        return out
    end
end

-- Load the framework
require 'core'
