require "core.utils.kbd"

local nvimexec = vim.api.nvim_exec2
local sys = vim.fn.systemlist
local Font = class("Font", {
  list = true,
  main = true,
  telescope_list = true,
  create_picker = true,
  run_picker = true,
  current = true,
})

function Font.list(pat)
  local out = sys "fc-list : family"
  local all = {}

  for i = 1, #out do
    local fs = strsplit(out[i], ",")
    for j = 1, #fs do
      all[fs[j]] = true
    end
  end

  pat = pat or "Mono"
  return list.filter(keys(all), function(x)
    return x:match(pat)
  end)
end

function Font:init(f, h)
  self.family = f or "Liberation Mono"
  self.height = h or "13"

  return self
end

function Font:__tostring()
  return self.family .. ":h" .. self.height
end

function Font:set()
  vim.o.guifont = tostring(self)
end

function Font:is_valid()
  local Fonts = Font.listall()

  for i = 1, #Fonts do
    if Fonts[i]:match(self.family) then
      return Fonts[i]
    end
  end

  return false
end

function Font.current()
  local res = nvimexec("set guifont?", { output = true })
  res = res.output
  res = strsplit(res, "=")[2]:match " *([^$]+)"

  if #res == 0 then
    return
  end

  local f, h = res:match "([^:]+):h([0-9]+)"
  return Font(f, h)
end

function Font:incheight(by)
  by = by or 1
  self.height = by + self.height
  self:set()
end

function Font:decheight(by)
  return self:incheight(-(by or 1))
end

function Font.telescope_list()
  return {
    results = Font.list(),
    entry_maker = function(x)
      return {
        display = x,
        value = x,
        ordinal = x,
      }
    end,
  }
end

function Font.create_picker()
  local _ = user.telescope()

  return _:create_picker(Font.telescope_list(), function(sel)
    sel = sel[1]
    local selFont = sel.value
    local height_picker = _:create_picker({
      results = list.range(10, 20),
      entry_maker = function(h)
        return {
          display = "height = " .. h,
          ordinal = h,
          value = { selFont, h },
        }
      end,
    }, function(hsel)
      hsel = hsel[1]
      Font(unpack(hsel.value)):set()
    end, {
      prompt_title = "pick height for " .. selFont,
      prompt = "13",
    }):find()
  end, {
    prompt_title = "pick Font",
  })
end

function Font.run_picker()
  Font.create_picker():find()
end

function Font.main()
  local cur = user.font or { "Liberation Mono", "12.5" }
  cur = Font(unpack(cur))
  user.currentfont = cur

  cur:set()

  vim.defer_fn(function()
    Kbd.map("n", "<leader>hf", Font.run_picker, "pick fonts")

    Kbd.map("n", "<localleader>+", function()
      Font.current():incheight()
    end, "inc font size")

    Kbd.map("n", "<localleader>-", function()
      Font.current():decheight()
    end, "dec font size")
  end, 100)
end

return Font
