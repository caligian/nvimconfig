local function get_lazy()
  -- Install lazy.nvim if not present
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
  if not ok then error "FATAL ERROR: Could not install lazy.nvim" end
end
get_lazy()

local function add_paths()
  -- Enable support for nvim-local luarocks
  local data_dir = vim.fn.stdpath "data"
  local home_dir = os.getenv "HOME" .. "/.nvim"
  local dir = table.concat({ os.getenv "HOME", ".luarocks" }, "/")

  package.cpath = package.cpath .. ";" .. dir .. "/share/lua/5.1/?.so"
  package.cpath = package.cpath .. ";" .. dir .. "/lib/lua/5.1/?.so"
  package.path = package.path .. ";" .. dir .. "/share/lua/5.1/?.lua"
  package.path = package.path .. ";" .. dir .. "/share/lua/5.1/?/?.lua"
  package.path = package.path .. ";" .. dir .. "/share/lua/5.1/?/init.lua"

  -- Enable support for user config in ~/.nvim
  package.path = package.path .. ";" .. home_dir .. "/lua/?.lua"
  package.path = package.path .. ";" .. home_dir .. "/lua/init.lua"
  package.path = package.path .. ";" .. home_dir .. "/lua/?/init.lua"
end
add_paths()

local function install_rocks()
  -- Install missing luarocks
  function install_luarock(rock, req)
    local _
    ok, _ = pcall(require, req)
    local cmd =
      string.format("luarocks --local --lua-version 5.1 install %s", dest, rock)
    if not ok then
      print("Attempting to install luarock " .. rock)

      local out = vim.fn.system(cmd)
      print(out)

      ok, _ = pcall(require, req)
      if not ok then
        error("Need luarock " .. rock .. " to load the framework")
      end
    end
  end

  install_luarock("lualogging", "logging.file")
  install_luarock("lrexlib-pcre2", "rex_pcre2")
  install_luarock('penlight', 'pl.path')
end
install_rocks()

local function create_globals(args)
  user = {}
  json = { encode = vim.fn.json_encode, decode = vim.fn.json_decode }

  -- Make some global variables
  local log_path = vim.fn.stdpath "config" .. "/nvim.log"
  logger = logging.file(log_path, "", "[%date] [%level]\n %message\n\n")

  path = require "pl.path"
  file = require "pl.file"
  dir = require "pl.dir"
  regex = require "rex_pcre2"
  utils = require "lua-utils.utils"
  array = require "lua-utils.array"
  dict = require "lua-utils.dict"
  class = require "lua-utils.class"
  multimethod = require "lua-utils.multimethod"
  exception = require "lua-utils.exception"
  str = require "lua-utils.str"

  local validate = require "lua-utils.validate"
  local fn = require "lua-utils.fn"
  local types = require "lua-utils.types"
  dict.each(validate, function(key, value) _G[key] = value end)
  dict.each(fn, function(key, value) _G[key] = value end)
  dict.each(types, function(key, value) _G[key] = value end)

  -- Delete the old log
  if path.exists(log_path) then vim.fn.system("rm " .. log_path) end
end
create_globals()

-- My modifications to penlight class
-- require "core.utils"
