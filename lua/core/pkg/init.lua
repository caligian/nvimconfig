local package_list = require 'core.pkg.list'

pcall(require, 'user.pkg')

user.pkg = user.pkg
user.packer = require 'packer'

user.packer.startup(function(use)
    for _, packer_form in pairs(package_list) do
        use(packer_form)
    end
end)
