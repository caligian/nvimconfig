require "core.lsp"

for ft, obj in pairs(filetype.filetypes) do
    if obj.lsp_server then
        obj:setup_lsp()
    end
end
