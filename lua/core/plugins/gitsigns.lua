user.plugins.gitsigns = {
	config = {
		on_attach = function(bufnr)
			local gs = package.loaded.gitsigns

			K.bind({ noremap = true, buffer = bufnr }, {
				"]c",
				function()
					if vim.wo.diff then
						return "]c"
					end
					vim.schedule(function()
						gs.next_hunk()
					end)
					return "<Ignore>"
				end,
				{ expr = true, desc = "Next hunk" },
			}, {
				"[c",
				function()
					if vim.wo.diff then
						return "[c"
					end
					vim.schedule(function()
						gs.prev_hunk()
					end)
					return "<Ignore>"
				end,
				{ expr = true, desc = "Previous hunk" },
			}, {
				"<leader>ghs",
				":Gitsigns stage_hunk<CR>",
				{ mode = "nv", desc = "Stage hunk" },
			}, {
				"<leader>ghr",
				":Gitsigns reset_hunk<CR>",
				"Reset hunk",
			}, {
				"<leader>gs",
				gs.stage_buffer,
				"Stage buffer",
			}, {
				"<leader>g!",
				gs.reset_buffer,
				"Reset buffer",
			}, {
				"<leader>ghu",
				gs.undo_stage_hunk,
				"Undo staged hunk",
			}, {
				"<leader>ghp",
				gs.preview_hunk,
				"Preview hubk",
			}, {
				"<leader>ghb",
				function()
					gs.blame_line({ full = true })
				end,
				"Blame line",
			}, {
				"<leader>gtb",
				gs.toggle_current_line_blame,
				"Blame current line",
			}, {
				"<leader>ghd",
				gs.diffthis,
				"Diff this",
			}, {
				"<leader>ghD",
				function()
					gs.diffthis("~")
				end,
				"Diff this (~)",
			}, { "<leader>gtd", gs.toggle_deleted }, {
				"ih",
				":<C-U>Gitsigns select_hunk<CR>",
				{ mode = "ox", desc = "Select hunk" },
			})
		end,
	},
}

req("user.plugins.gitsigns")
require("gitsigns").setup(user.plugins.gitsigns.config)
