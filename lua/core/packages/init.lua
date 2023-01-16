local package_list = require 'core.packages.list'
user.packages = merge_keepleft(user.require('user.packages') or {}, package_list)
user.packer = require 'packer'

user.packer.startup(function(use)
    for _, packer_form in pairs(package_list) do
        use(packer_form)
    end
end)
