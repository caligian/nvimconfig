require "core.utils.lsp"

for ft, obj in pairs(Filetype.filetypes) do
    if obj.lsp_server then
        obj:setup_lsp()
    end
end
