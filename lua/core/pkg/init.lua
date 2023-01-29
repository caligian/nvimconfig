local package_list = require 'core.pkg.list'
user.pkg = builtin.merge_keepleft(user. require('user.pkg') or {}, package_list)
user.packer = require 'packer'

user.packer.startup(function(use)
    for _, packer_form in pairs(package_list) do
        use(packer_form)
    end
end)
