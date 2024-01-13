local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
local exists = vim.loop.fs_stat(lazypath)

if not exists then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  }
end

vim.opt.rtp:prepend(lazypath)

local ok = pcall(require, "lazy")
if not ok then
  error "FATAL ERROR: Could not install lazy.nvim"
end

local home_dir = os.getenv "HOME" .. "/.nvim"
local luarocks = table.concat({ os.getenv "HOME", ".luarocks" }, "/")

package.cpath = package.cpath .. ";" .. luarocks .. "/share/lua/5.1/?.so"

package.cpath = package.cpath .. ";" .. luarocks .. "/lib/lua/5.1/?.so"

package.path = package.path .. ";" .. luarocks .. "/share/lua/5.1/?.lua"

package.path = package.path .. ";" .. luarocks .. "/share/lua/5.1/?/?.lua"

package.path = package.path .. ";" .. luarocks .. "/share/lua/5.1/?/init.lua"

-- Enable support for user config in ~/.nvim
package.path = package.path .. ";" .. home_dir .. "/lua/?.lua"

package.path = package.path .. ";" .. home_dir .. "/lua/init.lua"

package.path = package.path .. ";" .. home_dir .. "/lua/?/init.lua"

json = {
  encode = vim.fn.json_encode,
  decode = vim.fn.json_decode,
}

-- dir = require "pl.dir"
-- path = require "pl.path"
-- file = require "pl.file"
-- regex = require "rex_pcre2"

require "lua-utils"
require "core.utils.Path"
