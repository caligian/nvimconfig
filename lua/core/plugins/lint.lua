local nvimlint = require("lint")
local lint = plugin.get("lint")

lint.methods = {
	load_linters = function()
		list.each(filetype.filetypes, function(ft, conf)
			if not conf.linters then
				return
			end

			local specs = tolist(conf.linters)
			list.each(specs, function(obj)
				if isa.string(obj) then
					nvimlint.linters_by_ft[ft] = { obj }
				elseif isa.table(obj) then
					if obj.config then
						nvimlint.linters[ft] = obj.config
					else
						nvimlint.linters_by_ft[ft] = obj
					end
				end
			end)
		end)

		return { linters = nvimlint.linters, linters_by_ft = nvimlint.linters_by_ft }
	end,

	lint_buffer = function(bufnr)
		bufnr = bufnr or vim.fn.bufnr()

		buffer.call(bufnr, function()
			if nvimlint.linters_by_ft[vim.bo.filetype] then
				nvimlint.try_lint()
			end
		end)
	end,
}

lint.config = lint.methods.load_linters()

lint.mappings = {
	lint_buffer = { "n", "<leader>ll", lint.methods.lint_buffer, "Lint buffer" },
}

return lint
