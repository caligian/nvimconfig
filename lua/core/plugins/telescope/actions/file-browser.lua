local mod = user.telescope:module()

function mod.multi_delete(sel)
  vim.fn.system { "rm", "-r", sel[1] }
end

function mod.multi_force_delete(bufnr)
  vim.fn.system { "rm", "-rf", sel[1] }
end

function mod.touch(sel)
  local cwd = sel.Path._cwd
  local fname = vim.fn.input "Filename % "

  if #fname == 0 then
    return
  end

  local isdir = fname:match "/$"
  fname = Path.join(cwd, fname)

  if isdir then
    print("Creating directory", fname)

    vim.fn.system {
      "mkdir",
      fname,
    }
  else
    print("Creating empty file", fname)

    vim.fn.system {
      "touch",
      fname,
    }
  end
end

return mod
