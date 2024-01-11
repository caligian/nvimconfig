local mod = {}

function mod.delete(bufnr)
  local _ = user.telescope()
  local sels = _:selected(bufnr, true)

  list.each(sels, function(sel)
    print("rm -r", sel[1])
    vim.fn.system { "rm", "-r", sel[1] }
  end)
end

function mod.force_delete(bufnr)
  local _ = user.telescope()
  local sels = _:selected(bufnr)

  list.each(sels, function(sel)
    print("rm -rf", sel[1])
    vim.fn.system { "rm", "-rf", sel[1] }
  end)
end

function mod.touch(bufnr)
  local _ = user.telescope()
  local sel = _:selected(bufnr)
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
