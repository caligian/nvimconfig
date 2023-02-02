builtin.makepath(builtin, 'lang')
if not _G.Lang then
    builtin.lang = class.Lang()
end

local lang = Lang


function Lang._init(self, ft)
    ft = ft or vim.bo.filetype
    self.filetype = ft

    if not ft then
        error(sprintf('No lang configuration available for %s', ft))
    end

    return self
end

function Lang.setup(opts)
    opts = opts or {}
    assert(opts.command, 'No command table provided')
    assert(opts.command.compile, 'No compile command provided')

    for k, v in pairs(opts) do
        self[k] = v
    end
end

local function runner(cmd, args, fname)
    local 
    local opts = {
    }
end

function Lang.compile_buffer(self, bufnr, args)
    return vim.api.nvim_buf_call(function()
    end)
end
