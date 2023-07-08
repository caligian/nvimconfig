module = setmetatable({}, {type = 'module'})

function module.new(name)
    return setmetatable({}, {__tostring = dump, name = name, type = 'module'})
end
