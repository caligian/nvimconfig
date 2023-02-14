local action_state = V.require("telescope.actions.state")
local actions = V.require("telescope.actions")
local job = V.require("plenary.job")

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
        f(action_state.get_selected_entry())
      end
      actions.close(bufnr)
    end)
  end,
})

function mod.delete_recursively(sel)
  local path = sel[1]
  local cwd = sel.cwd

  print("rm -r " .. path)
  job:new({ command = "/sbin/rm", args = { "-r", path }, cwd = cwd }):start()
end

function mod.luafile(sel)
  local path = sel[1]

  print("Sourcing lua file " .. path)
  vim.cmd("luafile " .. path)
end

function mod.git_init(sel)
  local cwd = sel.cwd
  print("Running git init in " .. cwd)
  job:new({ command = "/usr/bin/git", args = { "init" }, cwd = cwd }):start()
end

function mod.touch(sel)
  local cwd = sel.cwd
  local fname = vim.fn.input("touch > ")
  fname = stringx.strip(fname)
  fname = path.join(cwd, fname)

  assert(#fname ~= 0, "No filename provided")

  print("Running touch " .. fname)

  vim.cmd("! touch " .. fname)
end

return mod
