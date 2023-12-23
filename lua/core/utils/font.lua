require "core.utils.kbd"

local nvimexec = vim.api.nvim_exec2
local sys = vim.fn.systemlist
local font = class "font"

function font.list(pat)
  local out = sys "fc-list : family"
  local all = {}

  for i = 1, #out do
    local fs = split(out[i], ",")
    for j = 1, #fs do
      all[fs[j]] = true
    end
  end

  pat = pat or "Mono"
  return list.filter(keys(all), function(x)
    return x:match(pat)
  end)
end

function font:init(f, h)
  self.family = f or "Liberation Mono"
  self.height = h or "13"

  return self
end

function font:__tostring()
  return self.family .. ":h" .. self.height
end

function font:set()
  vim.o.guifont = tostring(self)
  return self
end

function font:isvalid()
  local fonts = font.listall()

  for i = 1, #fonts do
    if fonts[i]:match(self.family) then
      return fonts[i]
    end
  end

  return false
end

function font.current()
  local res = nvimexec("set guifont?", { output = true })
  res = res.output
  res = split(res, "=")[2]:match " *([^$]+)"

  if #res == 0 then
    return
  end

  local f, h = res:match "([^:]+):h([0-9]+)"
  return font(f, h)
end

function font:incheight(by)
  by = by or 1
  self.height = by + self.height
  self:set()
end

function font:decheight(by)
  return self:incheight(-(by or 1))
end

font.telescope = {}
local tfont = font.telescope

function tfont.list()
  return {
    results = font.list(),
    entry_maker = function(x)
      return {
        display = x,
        value = x,
        ordinal = x,
      }
    end,
  }
end

function tfont.create_picker()
  local _ = require "core.utils.telescope"()
  return _:create_picker(tfont.list(), function(sel)
    sel = sel[1]
    local selfont = sel.value
    local height_picker = _:create_picker({
      results = list.range(10, 20),
      entry_maker = function(h)
        return {
          display = "height = " .. h,
          ordinal = h,
          value = { selfont, h },
        }
      end,
    }, function(hsel)
      hsel = hsel[1]
      font(unpack(hsel.value)):set()
    end, {
      prompt_title = "pick height for " .. selfont,
      prompt = "13",
    }):find()
  end, {
    prompt_title = "pick font",
  })
end

function tfont.run_picker()
  tfont.create_picker():find()
end

function font.main()
  local cur = user.font or { "Liberation Mono", "12.5" }
  cur = font(unpack(cur)):set()

  Kbd.map(
    "n",
    "<leader>hf",
    tfont.run_picker,
    "fonts picker"
  )
  Kbd.map("n", "<localleader>+", function()
    font.current():incheight()
  end, "inc font size")
  Kbd.map("n", "<localleader>-", function()
    font.current():decheight()
  end, "dec font size")
end

return font
