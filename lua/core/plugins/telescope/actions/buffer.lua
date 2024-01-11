local mod = {}

function mod.bwipeout(bufnr)
  local _ = user.telescope()
  local sel = _:selected(bufnr, true)

  list.each(sel, function(x)
    print("Wiping out buffer " .. x.bufnr)
    vim.cmd("bwipeout! " .. x.bufnr)
  end)
end

function mod.nomodified(bufnr)
  local _ = user.telescope()
  local sels = _:selected(bufnr, true)

  list.each(sels, function(sel)
    print("Setting buffer status to nomodified: " .. vim.fn.bufname(sel.bufnr))
    vim.api.nvim_buf_call(sel.bufnr, function()
      vim.cmd "set nomodified"
    end)
  end)
end

function mod.save(bufnr)
  local _ = user.telescope()
  local sels = _:selected(bufnr, true)

  list.each(sels, function()
    print("Saving buffer " .. sel.bufnr)
    local name = vim.fn.bufname(sel.bufnr)
    vim.cmd("w " .. name)
  end)
end

function mod.readonly(bufnr)
  local _ = user.telescope()
  local sels = _:selected(bufnr, true)
  list.each(sels, function(sel)
    print("Setting buffer to readonly: " .. vim.fn.bufname(sel.bufnr))
    vim.api.nvim_buf_call(sel.bufnr, function()
      vim.cmd "set nomodifiable"
    end)
  end)
end

return mod
