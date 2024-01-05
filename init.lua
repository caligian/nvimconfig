if not user then
  local data_dir = vim.fn.stdpath "data"
  user = {}
  local dir = vim.fn.stdpath "config"
  local user_dir = table.concat({ os.getenv "HOME", ".nvim" }, "/")
  local plugins_dir = table.concat({ data_dir, "lazy" }, "/")
  local log_path = table.concat({ data_dir, "messages" }, "/")

  user.paths = {
    config = dir,
    user = user_dir,
    data = data_dir,
    plugins = plugins_dir,
    logs = log_path,
    servers = table.concat({ data_dir, "lsp-servers" }, "/"),
  }
end

vim.o.autochdir = true
vim.o.showcmd = false
vim.opt.shortmess:append "I"

vim.keymap.set("n", "<space>fv", ":w <bar> :luafile %<CR>", { noremap = true, desc = "source file" })

vim.keymap.set("n", "<space>fs", ":w<CR>", { noremap = true, desc = "save file" })

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*.lua",
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
  end,
})

-- Bootstrap with requisite rocks and lazy.nvim
require "bootstrap"

if Path.exists(user.paths.logs) then
  Path.delete(user.paths.logs)
end

local winapi = {}
local bufapi = {}
local api = {}
local create = {}
local del = {}
local list = {}
local tabpage = {}
local get = {}
local set = {}

dict.each(vim.api, function(key, value)
  if key:match "^nvim_buf" then
    key = key:gsub("^nvim_buf_", "")
    bufapi[key] = value
  elseif key:match "^nvim_win" then
    key = key:gsub("^nvim_win_", "")
    winapi[key] = value
  elseif key:match "nvim_list" then
    list[(key:gsub("^nvim_list_", ""))] = value
  elseif key:match "nvim_del_" then
    del[(key:gsub("^nvim_del_", ""))] = value
  elseif key:match "^nvim_tabpage" then
    tabpage[(key:gsub("^nvim_tabpage_", ""))] = value
  elseif key:match "^nvim_get" then
    get[(key:gsub("^nvim_get_", ""))] = value
  elseif key:match "^nvim_set" then
    get[(key:gsub("^nvim_set_", ""))] = value
  elseif key:match "nvim_create" then
    create[(key:gsub("^nvim_create_", ""))] = value
  elseif key:match "^nvim_" then
    api[(key:gsub("^nvim_", ""))] = value
  end
end)

api.win = winapi
api.buf = bufapi
api.del = del
api.list = list
api.create = create
api.tabpage = tabpage
api.set = set
api.get = get

nvim = setmetatable(api, {
  __index = function(self, key)
    local f = rawget(self, "api")["nvim_" .. key]
    if f then
      rawset(self, key, f)
      return f
    end
  end,
})

-- Load the framework
require "core.utils"
require "core"
