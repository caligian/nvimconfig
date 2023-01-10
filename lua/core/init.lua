user = {}
user.builtin = {}
user.config = {}

inspect = function (...)
    local final_s = ''

    for _, obj in ipairs({...}) do
        final_s = final_s .. vim.inspect(obj) .. "\n\n"
    end

    vim.api.nvim_echo({{final_s}}, false, {})
end

require 'core.packages'
require 'core.keybindings.defaults'
require 'core.autocmds.defaults'

