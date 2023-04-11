local M = utils.telescope.create_actions_mod()
local B = Bookmarks
local Bpicker = require("core.bookmarks.telescope.picker")

local function get_fname(sel)
	return sel.cwd .. "/" .. sel[1]
end

function M.add_bookmark(sel)
	local fname = get_fname(sel)
	print("Adding bookmark " .. fname)
	B.add(fname)
end

function M.remove_bookmark(sel)
	local fname = get_fname(sel)
	print("Removing bookmark " .. fname)
	if not B.bookmarks[fname] then
		return
	end
	Bpicker.run_marks_remover_picker(fname)
end

function M.delete(sel)
	local fname = get_fname(sel)
	print("rm -r " .. fname)
	print(vim.fn.system({ "rm", "-r", fname }))
end

return M
