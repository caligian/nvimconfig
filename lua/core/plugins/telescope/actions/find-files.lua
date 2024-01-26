local function get_fname(sel)
  return sel.cwd .. "/" .. sel[1]
end

local mod = user.telescope:module()

mod.multi_delete = function(sel)
  vim.fn.system { "rm", "-r", get_fname(sel) }
end

mod.touch = function(sel)
  local filename = vim.fn.input "touch file % "
  if #filename == 0 then
    return
  end

  if not filename:match '^/' then
    filename = sel.cwd .. '/' .. filename
  end
   
  if filename:match "/$" then
    vim.fn.system { "mkdir", "-p", filename }
  else
    vim.fn.system { "touch", filename }
  end
end

mod.touch_and_open = function(sel)
  local filename = vim.fn.input "touch file % "
  if #filename == 0 then
    return
  end

  if not filename:match '^/' then
    filename = sel.cwd .. '/' .. filename
  end
   
  if filename:match "/$" then
    vim.fn.system { "mkdir", "-p", filename }
  else
    vim.fn.system { "touch", filename }
  end

  vim.cmd(":e " .. filename)
end

return mod
