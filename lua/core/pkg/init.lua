local package_list = builtin.require 'core.pkg.list'

pcall(builtin.require, 'user.pkg')

user.pkg = user.pkg
user.packer = builtin.require 'packer'

user.packer.startup(function(use)
    for _, packer_form in pairs(package_list) do
        use(packer_form)
    end
end)
