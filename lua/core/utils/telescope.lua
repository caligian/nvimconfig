telescope = {}
local telescope = telescope

telescope.load = function(override)
	local opts = dict.merge({
		exists = require("telescope"),
		pickers = require("telescope.pickers"),
		actions = require("telescope.actions"),
		action_state = require("telescope.actions.state"),
		sorters = require("telescope.sorters"),
		finders = require("telescope.finders"),
		conf = try_require("telescope.config", function(M)
			return M.values
		end),
		ivy = try_require("telescope.themes", function(M)
			return dict.merge(M.get_dropdown(), {
				disable_devicons = true,
				previewer = false,
				extensions = {},
				layout_config = {
					height = 0.8,
					width = 0.9,
				},
			})
		end),
	}, override or {})

	return dict.merge({
		get_selected = function(self, bufnr, close)
			if close == nil then
				close = true
			end

			local picker = self.action_state.get_current_picker(bufnr)
			if close then
				self.actions.close(bufnr)
			end
			local nargs = picker:get_multi_selection()

			if #nargs > 0 then
				return nargs
			end
			return { self.action_state.get_selected_entry() }
		end,

		create_picker = function(self, items, mappings, opts)
			opts = opts or {}

			-- If opts.finder is missing, then only items will be used
			if not opts.finder and items then
				opts.finder = self.finders.new_table(items)
			end

			opts.sorter = opts.sorter or self.sorters.get_fzy_sorter()

			if mappings then
				mappings = array.to_array(mappings)
				local attach_mappings = opts.attach_mappings
				opts.attach_mappings = function(prompt_bufnr, map)
					if mappings then
						local default = mappings[1]
						if default then
							self.actions.select_default:replace(function()
								default(prompt_bufnr)
							end)
						end
						array.each(array.rest(mappings), function(x)
							map(unpack(x))
						end)
					end
					if attach_mappings then
						attach_mappings(prompt_bufnr, map)
					end
					return true
				end
			end
			return self.pickers.new(self.ivy, opts)
		end,

		create_actions = function(self, no_close)
			return setmetatable({}, {
				__newindex = function(self, name, f)
					rawset(self, name, function(bufnr)
						array.each(self:get_selected(bufnr, no_close), function(sel)
							return f(sel, bufnr)
						end)
					end)
				end,
			})
		end,

		create_menu = function(self, title, spec)
			return self:create_picker({
				results = spec,
				entry_maker = function(entry)
					return {
						value = entry[1],
						display = entry[1],
						ordinal = -1,
						callback = entry[2],
					}
				end,
			}, function(prompt_bufnr)
				local sel = self:get_selected(prompt_bufnr)[1]
				sel.callback(sel)
			end, {
				prompt_title = title,
			})
		end,

		run_picker = function(...)
			return self:create_picker(...):find()
		end,
	}, opts)
end
