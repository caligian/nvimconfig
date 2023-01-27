local package_list = require 'core.packages.list'
user.packages = merge_keepleft(user.require('user.packages') or {}, package_list)
user.packer = require 'packer'

user.packer.startup(function(use)
    for _, packer_form in pairs(package_list) do
        use(packer_form)
    end
end)

local pkgs = {}
pkgs.config_path = join_path(vim.fn.stdpath('config'), 'lua', 'core', 'packages', 'configs')

function pkgs.has_config(spec)
    local name = basename(spec[1]):gsub('[^a-zA-Z0-9_-]', '_')
    local path = join_path(pkgs.config_path, name .. '.lua')
    path = vim.fn.glob(path)

    return path ~= '' and path or false
end


print(pkgs.has_config {'telescope.nvimz'} == '')

