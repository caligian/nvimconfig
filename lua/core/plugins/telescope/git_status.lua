local action_state = require "telescope.actions.state"
local actions = require "telescope.actions"
local mod = require('core.plugins.telescope.utils').create_actions()

local function gitcmd(op, fname)
  vim.fn.system(sprintf("git %s %s", op, fname))
end

function mod.stage(sel)
  print("git stage " .. sel.path)
  gitcmd("stage", sel.path)
end

function mod.add(sel)
  print("git add " .. sel.path)
  gitcmd("add", sel.path)
end

function mod.unstage(sel)
  print("git unstage " .. sel.path)
  gitcmd("unstage", sel.path)
end

return mod
