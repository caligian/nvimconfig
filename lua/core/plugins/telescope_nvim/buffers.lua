local action_state = V.require('telescope.actions.state')
local actions = V.require('telescope.actions')

local mod = setmetatable({}, {
  __newindex = function(self, name, f)
    rawset(self, name, function(bufnr)
      local picker = action_state.get_current_picker(bufnr)
      local nargs = picker:get_multi_selection()
      if #nargs > 0 then
        for _, value in ipairs(nargs) do
          f(value)
        end
      else
        f(picker:get_current_selection())
      end
    end)
  end,
})

function mod.bwipeout(sel)
  print('Wiping out buffer ' .. sel.bufnr)
  vim.cmd('bwipeout ' .. sel.bufnr)
end

function mod.nomodified(sel)
  print('Setting buffer status to nomodified: ' .. vim.fn.bufname(sel.bufnr))
  vim.api.nvim_buf_call(sel.bufnr, function() vim.cmd('set nomodified') end)
end

function mod.save(sel)
  print('Saving buffer ' .. sel.bufnr)
  local name = vim.fn.bufname(sel.bufnr)
  vim.cmd('w ' .. name)
end

function mod.readonly(sel)
  print('Setting buffer to readonly: ' .. vim.fn.bufname(sel.bufnr))
  vim.api.nvim_buf_call(sel.bufnr, function() vim.cmd('set nomodifiable') end)
end

return mod
