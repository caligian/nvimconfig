require "core.utils.lsp"

for ft, obj in pairs(Filetype.filetypes) do
    if obj.lsp_server then
        Filetype.setup_lsp(obj)
    end
end
