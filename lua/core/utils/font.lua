font = {
    fonts = {},
    exception = {
        invalid = exception "invalid font name provided",
        not_set = exception "font has not been set",
    },
    default = { "Liberation Mono", h = 14 },
}

local valid = {
    h = "number",
    w = "number",
    b = "boolean",
    i = "boolean",
    u = "boolean",
    s = "boolean",
    c = "string",
}

local valid_attribs = {__nonexistent = false}
local mod = {}

for key, value in pairs(valid) do
    valid_attribs["opt_" .. key] = value
end

local function checkattribs(attribs)
    validate {attribs = {valid_attribs, attribs} }
end

function font.get(name, callback)
    local exists = font.fonts[name]
    if exists and callback then
        callback(exists)
    end

    return exists
end

function mod:tostring()
    local out = { self.family }
    local i = 2

    dict.each(self:get_attribs(), function(key, value)
        out[i] = ":" .. key .. value
    end)

    return array.join(out, "")
end

function font.new(family, attribs)
    if not family then
        font.exception.invalid_font:throw()
    end

    local self = {}
    attribs = attribs or {}

    checkattribs(attribs)

    self.family = family

    dict.merge(self, attribs)

    self.h = self.h or 10

    dict.merge(self, mod)
    font.fonts[self.family] = self

    return self
end

function mod:get_attribs()
    local out = {}
    dict.each(self, function(key, value)
        if valid[key] then
            out[key] = value
        end
    end)

    return out
end

function mod:set()
    vim.o.guifont = self:tostring()
end
function mod:is_current()
    return vim.o.guifont == self:tostring()
end

local function assertcurrent(self)
    if self:iscurrent() then
        return self
    end
    font.exception.not_set:throw(self.family)
end

function mod:inc(by)
    self = assertcurrent(self)
    self.h = self.h + by
    self:set()

    return self
end

function mod:dec(by)
    return self:inc(-1 * by)
end

function font.load_spec(spec)
    spec = vim.deepcopy(spec)
    local f = spec[1]
    local attribs = dict.extract(spec)
    f = font.new(f, attribs)

    return f
end

function font.set_default()
    local f = font.load_spec(font.default)
    f:set()

    return f
end

function font.load_user()
    vim.o.guifont = ""
    array.each(user.fonts, font.append)
    user.current_font = font.fonts[user.fonts[1][1]]
    user.current_font:set()
end
