local packer = require 'packer'
builtin.makepath(user.pkg, 'package')

if not Package then class.Package() end
user.pkg._packer_forms = {}

builtin.require 'user.pkg'
builtin.require 'user.pkg.list'

function Package._init(self, repo, isrock)
    self.repo = repo
    self.name = path.basename(repo)
    self.rock = isrock
    user.pkg.package[self.name] = self

    return self
end

function Package.setup(self, opts)
    opts = opts or {}
    local _form = { self.repo, name = self.name }

    for k, v in pairs(opts) do
        _form[k] = v
    end

    user.pkg._packer_forms[self.name] = _form
    user.pkg.package[self.name] = self
    _form.rock = self.rock

    self.init = true

    return self
end

function Package.compile()
    local final = {}

    for _, pkg in pairs(user.pkg.package) do
        if pkg.init == nil then
            pkg:setup()
        end
    end

    for k, conf in pairs(user.pkg._packer_forms) do
        if conf.disable then
            user.pkg._packer_forms[k] = nil
        else
            builtin.append(final, conf)
        end
    end

    return final
end

function Package.startup()
    local final = Package.compile()

    if #final == 0 then
        error('No packages loaded at all. Please setup packages')
    end

    return packer.startup(function(use)
        for _, pkg in pairs(final) do
            if pkg.rock then
                pkg.rock = nil
                packer.use_rocks(pkg)
            else
                use(pkg)
            end
        end
    end)
end

builtin.require 'core.pkg.list'
Package.startup()
