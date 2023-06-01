Font = Font or class "Font"
Font.InvalidFontException = exception "invalid font name provided"
Font.NotSetException = exception "font has not been set"
Font.default = {"Liberation Mono", h = 14}
Font.STATE = Font.STATE or {}

local valid = {
	h = 'number',
	w = 'number',
	b = 'boolean',
	i = 'boolean',
	u = 'boolean',
	s = 'boolean',
	c = 'string',
}

local valid_attribs = {}
for key, value in pairs(valid) do
	valid_attribs['opt_' .. key] = value
end

local function checkattribs(attribs)
  validate.attribs(valid_attribs, attribs)
end

function Font:init(family, attribs)
  if not family then Font.InvalidFontException:throw() end

	attribs = attribs or {}
	checkattribs(attribs)
  self.family = family

  dict.merge(self, attribs)

  self.h = self.h or 10
  self.font = tostring(self)

  dict.update(Font.STATE, self.family, self)
end

function Font:__tostring()
  local out = { self.family }
  local i = 2

  dict.each(self:getattribs(), function(key, value) out[i] = ":" .. key .. value end)

  return array.join(out, "")
end

function Font:getattribs()
	local out = {}
	dict.each(self, function(key, value)
		if valid[key] then
			out[key] = value
		end
	end)

	return out
end

function Font:tostring()
	return tostring(self)
end

function Font:set() vim.o.guifont = tostring(self) end

function Font:iscurrent() return vim.o.guifont == tostring(self) end

local function assertcurrent(self)
  if self:iscurrent() then return self end
  Font.NotSetException:throw(self.family)
end

function Font:inc(by)
  self = assertcurrent(self)
  self.h = self.h + by
  self:set()

  return self
end

function Font:dec(by) return self:inc(-1 * by) end

function Font.fromspec(spec)
	spec = vim.deepcopy(spec)
	local font = spec[1]
	local attribs = dict.extract(spec)
	font = Font(font, attribs)

	return font
end

function Font.setdefault()
  local font = Font.fromspec(Font.default)
  font:set()

  return font
end

function Font.append(font_or_spec)
	validate.font(is {Font, 'table', 'string'}, font_or_spec)
	local font
	local function push(s) vim.opt.guifont:append(s) end

	if is_a.string(font_or_spec) then
		push(font_or_spec)
	elseif is_a.Font(font_or_spec) then
		push(tostring(font_or_spec))
	else 
		push(tostring(Font.fromspec(font_or_spec)))
	end
end

function Font.loaduser()
	vim.o.guifont = ""
	array.each(user.fonts, Font.append)
  user.currentfont = Font.STATE[user.fonts[1][1]]
  user.currentfont:set()
end
