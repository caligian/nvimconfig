local align = plugin.get("align")

align.mappings = {
	opts = { leader = true, noremap = true },
	align = { "=", ":EasyAlign ", { desc = "Align by regexp" } },
	align_region = {
		"=",
		":'<,'>EasyAlign ",
		{ mode = "v", desc = "Align by regexp" },
	},
}

align.config = {}

function align:setup()
	list.each(self.config or {}, function(key, value)
		vim.g[key] = value
	end)
end

return align
