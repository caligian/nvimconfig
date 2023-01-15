require 'logging.file'

user.logger = logging.file {
    filename = vim.fn.stdpath('config') .. 'nvim.log',
}

function user.require(s)
    local success, err = pcall(require, s)
    if not success then
        user.builtin.logger:debug(err)
        append(user.log, err)
    else
        return success
    end
end
