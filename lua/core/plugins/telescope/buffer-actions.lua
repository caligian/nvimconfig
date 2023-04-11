local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local mod = utils.telescope.create_actions_mod()
local B = Bookmarks
local Bpicker = require("core.bookmarks.telescope.picker")

function mod.bwipeout(sel)
	print("Wiping out buffer " .. sel.bufnr)
	vim.cmd("bwipeout! " .. sel.bufnr)
end

function mod.nomodified(sel)
	print("Setting buffer status to nomodified: " .. vim.fn.bufname(sel.bufnr))
	vim.api.nvim_buf_call(sel.bufnr, function()
		vim.cmd("set nomodified")
	end)
end

function mod.save(sel)
	print("Saving buffer " .. sel.bufnr)
	local name = vim.fn.bufname(sel.bufnr)
	vim.cmd("w " .. name)
end

function mod.readonly(sel)
	print("Setting buffer to readonly: " .. vim.fn.bufname(sel.bufnr))
	vim.api.nvim_buf_call(sel.bufnr, function()
		vim.cmd("set nomodifiable")
	end)
end

function mod.add_bookmark(sel)
	local bufnr = sel.bufnr
	print("Adding bookmark " .. vim.api.nvim_buf_get_name(bufnr))
	B.add(bufnr)
end

function mod.remove_bookmark(sel)
	local bufnr = sel.bufnr
	local bufname = vim.api.nvim_buf_get_name(bufnr)
	local exists = B.bookmarks[bufname]
	if not exists then
		return
	end
	Bpicker.run_marks_remover_picker(bufname)
end

return mod
