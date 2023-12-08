require("core.utils.lsp")

local lsp = plugin.get("lsp")

for ft, obj in pairs(filetype.filetypes) do
	if obj.lsp_server then
		filetype.setup_lsp(obj)
	end
end

return lsp
