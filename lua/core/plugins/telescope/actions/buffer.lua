local mod = user.telescope:module()

function mod.multi_bwipeout(sel)
  vim.cmd("bwipeout! " .. sel.bufnr)
end

function mod.multi_nomodified(sel)
  nvim.buf.set_option(sel.bufnr, 'modified', false)
end

function mod.multi_save(sel)
  vim.cmd(':w! ' .. nvim.buf.get_name(sel.bufnr))
end

function mod.multi_readonly(sel)
  nvim.buf.set_option(sel.bufnr, 'modifiable', false)
end

return mod
