local fennel = require 'fennel'
local config_path = vim.fn.stdpath('config')
local user_config_path = path.join(os.getenv('HOME'), '.nvim', 'user')

function fennel.set_paths()
    local search_paths = {
        path.join(user_config_path, 'lua', '?.fnl'),
        path.join(user_config_path, 'lua', '?', 'init.fnl'),
        path.join(user_config_path, 'fnl', '?.fnl'),
        path.join(user_config_path, 'fnl', '?', 'init.fnl'),
        path.join(config_path, 'lua', '?.fnl'),
        path.join(config_path, 'lua', '?', 'init.fnl'),
        path.join(config_path, 'fnl', '?.fnl'),
        path.join(config_path, 'fnl', '?', 'init.fnl'),
    }

    fennel.path =  fennel.path .. ';' .. table.concat(search_paths, ';')

    return fennel.path
end

-- Buffers will be saved at ~/.config/nvim/lua/compiled/
function fennel.compile_buffer(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    local bufname = vim.fn.bufname(bufnr)
    assert(bufname:match('fnl$'), 'This is not a fennel buffer')

    return vim.api.nvim_buf_call(bufnr, function ()
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        lines = table.concat(lines, "\n")
        local lua_lines = fennel.compileString(lines)
        local dest = path.join(config_path, 'lua', 'compiled')

        if not path.exists(dest)  then
            dir.makepath(dest)
        end

        bufname = bufname:gsub('fnl$', 'lua')
        dest = path.join(dest, bufname)
        file.write(dest, lua_lines)

        return lua_lines
    end)
end

function fennel.eval_buffer(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    local bufname = vim.fn.bufname(bufnr)
    assert(bufname:match('fnl$'), 'This is not a fennel buffer')

    return vim.api.nvim_buf_call(bufnr, function ()
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        lines = table.concat(lines, "\n")
        return fennel.eval(lines)
    end)
end

user.fennel = fennel

return fennel
