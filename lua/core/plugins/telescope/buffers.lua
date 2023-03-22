local action_state = require "telescope.actions.state"
local actions = require "telescope.actions"
local mod = require('core.plugins.telescope.utils').create_actions()

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

function mod.bookmark(sel)
  sel = path.abspath(sel.filename)
  print('Bookmarking buffer: ' .. sel)
  Bookmarks.add(sel)
end

return mod
