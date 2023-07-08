require 'core.utils.module'
require 'core.utils.exception'

struct = module.new 'struct'

struct.exception = exception.new {
    invalid_attribute = 'undefined attribute passed'
}

function struct.is_struct(st)
    if not types.is_table(st) then
        return
    elseif not utils.mtget(st, "type") == "struct" then
        return
    end

    return utils.mtget(st, "name")
end

function struct.name(st) return struct.is_struct(st) end

function struct.equals(st1, st2, opts)
    assert(struct.is_struct(st1), 'invalid_struct1')
    assert(struct.is_struct(st2), 'invalid_struct2')

    opts = opts or {}
    local absolute = opts.compare_tables
    local callback = opts.callback

    if not struct.is_struct(st1) then return false end

    if not struct.is_struct(st2) then return false end

    local ks1 = dict.keys(st1)
    local ks2 = dict.keys(st2)

    if #ks1 ~= #ks2 then return false end

    for i = 1, #ks1 do
        local k = ks1[i]
        local st1_v = st1[k]
        local st2_v = st2[k]

        if type(st1_v) ~= type(st2_v) then return false end

        if types.is_table(st1_v) then
            if absolute and not dict.compare(st1_v, st2_v, callback, true) then
                return false
            elseif not st1_v == st2_v then
                return false
            end
        elseif not st1_v == st2_v then
            return false
        end
    end

    return true
end

function struct.not_equals(...)
    return not struct.equals(...)
end

function struct.new(name, valid_attribs)
    assert(valid_attribs, 'no_valid_attribs')

    local mt = {name = name, type = 'struct', valid_attribs = array.todict(valid_attribs)}

    return function(attribs)
        attribs = copy(attribs or {})

        dict.each(attribs, function (key, value)
            struct.exception.invalid_attribute:assert(mt.valid_attribs[key], key)
        end)

        return setmetatable(attribs, mt)
    end
end

function struct.include(dst, src, opts)
    assert(struct.is_struct(dst), 'invalid_dst_struct')
    assert(struct.is_struct(src), 'invalid_src_struct')

    opts = opts or {}
    local overwrite = opts.overwrite
    local missing = opts.missing 

    if overwrite == nil then overwrite = true end
    if missing == nil then missing = true end

    dict.each(src, function (key, value)
        if not dst[key] then 
            if missing then
                dst[key] = value
            end
        elseif overwrite then
            dst[key] = value
        end
    end)

    return dst
end

types.is_struct = struct.is_struct
