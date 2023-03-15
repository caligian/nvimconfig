-- Install lazy.nvim if not present
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
local exists = vim.loop.fs_stat(lazypath)
if not exists then
  print(vim.fn.system {
    "git",
    "clone",
    "--table.filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local ok = pcall(require, "lazy")
if not ok then
  error "FATAL ERROR: Could not install lazy.nvim"
end

-- Enable support for nvim-local luarocks
local config_dir = vim.fn.stdpath "config"
local home_dir = os.getenv "HOME" .. "/.nvim"
package.cpath = package.path .. ";" .. config_dir .. "/luarocks/share/lua/5.1/?.so"
package.cpath = package.path .. ";" .. config_dir .. "/luarocks/lib/lua/5.1/?.so"
package.path = package.path .. ";" .. config_dir .. "/luarocks/share/lua/5.1/?.lua"
package.path = package.path .. ";" .. config_dir .. "/luarocks/share/lua/5.1/?/?.lua"
package.path = package.path .. ";" .. config_dir .. "/luarocks/share/lua/5.1/?/init.lua"

-- Enable support for user config in ~/.nvim
package.path = package.path .. ";" .. home_dir .. "/lua/?.lua"
package.path = package.path .. ";" .. home_dir .. "/lua/init.lua"
package.path = package.path .. ";" .. home_dir .. "/lua/?/init.lua"

-- Install missing luarocks
local dest = vim.fn.stdpath "config" .. "/luarocks"
function install_luarock(rock, req)
  local ok, _ = pcall(require, req)
  local cmd = string.format("luarocks --lua-version 5.1 --tree %s install %s", dest, rock)
  if not ok then
    print("Attempting to install luarock " .. rock)

    vim.fn.system(cmd)

    ok, _ = pcall(require, req)
    if not ok then
      error("Need luarock " .. rock .. " to load the framework")
    end
  end
end

install_luarock("lua-yaml", "yaml")
install_luarock("penlight", "pl.stringx")
install_luarock("lualogging", "logging.file")
install_luarock("lrexlib-pcre2", "rex_pcre2")

-- Make some global variables
local log_path = vim.fn.stdpath "config" .. "/nvim.log"
yaml = require "yaml"
path = require "pl.path"
file = require "pl.file"
dir = require "pl.dir"
regex = require "rex_pcre2"
json = { encode = vim.json_encode, decode = vim.json_decode }
logger = logging.file(log_path, "", "[%date] [%level]\n %message\n\n")
user = {}

-- Delete the old log
if path.exists(log_path) then
  vim.fn.system("rm " .. log_path)
end

-- My modifications to penlight class
require "utils"
