local action_state = require "telescope.actions.state"
local actions = require "telescope.actions"
local mod = utils.telescope.create_actions_mod()
local Bookmark = require 'core.bookmarks.Bookmark'

function mod.bwipeout(sel)
  print("Wiping out buffer " .. sel.bufnr)
  vim.cmd("bwipeout! " .. sel.bufnr)
end

function mod.nomodified(sel)
  print("Setting buffer status to nomodified: " .. vim.fn.bufname(sel.bufnr))
  vim.api.nvim_buf_call(sel.bufnr, function()
    vim.cmd "set nomodified"
  end)
end

function mod.save(sel)
  print("Saving buffer " .. sel.bufnr)
  local name = vim.fn.bufname(sel.bufnr)
  vim.cmd("w " .. name)
end

function mod.readonly(sel)
  print("Setting buffer to readonly: " .. vim.fn.bufname(sel.bufnr))
  vim.api.nvim_buf_call(sel.bufnr, function()
    vim.cmd "set nomodifiable"
  end)
end

function mod.add_bookmark(sel)
  print("Adding bookmark " .. buffer.name(sel.bufnr))
  Bookmark.add_path(sel.bufnr)
end

function mod.remove_bookmark(sel)
  print('Removing bookmark ' .. buffer.name(sel.bufnr))
  local exists = Bookmark.get(sel.bufnr)
  if not exists then return end
  local picker = exists:create_picker(true)
  if picker then return picker:find() end
  exists:delete()
end

return mod
