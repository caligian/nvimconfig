require "core.utils.telescope"

local _ = load_telescope()
local mod = {}

function mod.delete(bufnr)
    local sels = _.selected(bufnr, true)

    array.each(sels, function(sel)
        print("rm -r", sel[1])
        vim.fn.system { "rm", "-r", sel[1] }
    end)
end

function mod.force_delete(bufnr)
    local sels = _.selected(bufnr)

    array.each(sels, function(sel)
        print("rm -rf", sel[1])
        vim.fn.system { "rm", "-rf", sel[1] }
    end)
end

function mod.touch(bufnr)
    local sel = _.selected(bufnr, true)
    local cwd = sel.Path._cwd
    local fname = vim.fn.input "Filename % "
    if #fname == 0 then
        return
    end
    local is_dir = fname:match "/$"
    fname = path.join(cwd, fname)

    if is_dir then
        print("Creating directory", fname)
        vim.fn.system {
            "mkdir",
            fname,
        }
    else
        print("Creating empty file", fname)
        vim.fn.system {
            "touch",
            fname,
        }
    end
end

return mod
