--[[
A must use fix for neovide/nvim-qt when running directly from your DE menu
This reads the .bashrc/.zshrc and reads all the environment variables and sets them in vim
This should be enough for most problems LUA_PATH and PATH problems
--]]

local rc_path = os.getenv "HOME" .. "/.bashrc"
local bashrc = ""
local lines = {}
local env = {}

local fh = io.open(rc_path, "r")
if not fh then
  fh = io.open(rc_path:gsub(".bashrc$", ".zshrc"))
  if not fh then
    error(rc_path .. " does not exist")
  end
end

bashrc = fh:read "*a"
for match in bashrc:gmatch "[^\n]+" do
  lines[#lines + 1] = match
end

table.foreach(lines, function(_, line)
  local export_start, export_end = line:find "^export "
  if export_start then
    line = line:sub(export_end + 1)
  end

  local word, rest = line:match "^([A-Z][A-Za-z0-9_]+)=(.+)"
  if not word then
    return
  end

  rest = rest:gsub("^%s+", "")
  rest = rest:gsub("%s+$", "")
  rest = rest:gsub([=[["']]=], "")
  rest = rest:gsub("%$HOME", os.getenv "HOME")

  env[word] = rest
end)

for key, value in pairs(env) do
  local s
  if value:match "^[0-9]+$" then
    s = ("let $%s = %s"):format(key, value)
  else
    s = ('let $%s = "%s"'):format(key, value)
  end

  vim.cmd(s)
end

package.path = env.LUA_PATH
package.cpath = env.LUA_CPATH
