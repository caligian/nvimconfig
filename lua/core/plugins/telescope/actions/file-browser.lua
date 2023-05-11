require "core.utils.telescope"

local _ = utils.telescope.load()
local mod = _.create_actions_mod()
local Bookmark = require "core.utils.Bookmark"

function mod.delete(sel)
  print("rm -r", sel[1])
  vim.fn.system { "rm", "-r", sel[1] }
end

function mod.force_delete(sel)
  print("rm -rf", sel[1])
  vim.fn.system { "rm", "-rf", sel[1] }
end

function mod.add_bookmark(sel)
  print("Adding bookmark " .. sel[1])
  Bookmark.add_path(sel[1])
end

function mod.remove_bookmark(sel)
  print("Removing bookmark " .. sel[1])
  Bookmark.remove_path(sel[1])
end

function mod.touch(sel)
  pp(sel)
  local cwd = sel.Path._cwd
  local fname = vim.fn.input "Filename % "
  if #fname == 0 then
    return
  end
  local is_dir = fname:match "/$"
  fname = path.join(cwd, fname)

  if is_dir then
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
