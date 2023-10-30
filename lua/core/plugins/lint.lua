local nvimlint = require "lint"
local lint = plugin.get "lint"

lint.methods = {
    load_linters = function()
        each(filetype.filetypes, function(ft, conf)
            if not conf.linters then
                return
            end

            local specs = to_list(conf.linters)
            each(specs, function(obj)
                if is_a.string(obj) then
                    nvimlint.linters_by_ft[ft] = { obj }
                elseif is_a.table(obj) then
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
