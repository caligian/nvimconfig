local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")

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
