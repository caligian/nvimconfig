function utils.highlight(hi)
  local ok, out = pcall(vim.api.nvim_exec, "hi " .. hi, true)
  if not ok then
    return {}
  end

  hi = {}
  out = vim.split(out, " +")
  out = array.grep(out, function(c)
    if string.match_any(c, "xxx", "cleared") then
      return false
    else
      return true
    end
  end)
  out = array.slice(out, 1, #out)

  array.each(out, function(i)
    local attrib, value = unpack(vim.split(i, "="))
    if value then
      hi[attrib] = value
    end
  end)

  return hi
end

function utils.hex2rgb(hex)
  hex = hex:gsub("#", "")
  return tonumber("0x" .. hex:sub(1, 2)),
    tonumber("0x" .. hex:sub(3, 4)),
    tonumber("0x" .. hex:sub(5, 6))
end

-- Taken from https://github.com/iskolbin/lhsx/blob/master/hsx.lua
function utils.rgb2hsv(r, g, b)
  local M, m = math.max(r, g, b), math.min(r, g, b)
  local C = M - m
  local K = 1.0 / (6.0 * C)
  local h = 0.0
  if C ~= 0.0 then
    if M == r then
      h = ((g - b) * K) % 1.0
    elseif M == g then
      h = (b - r) * K + 1.0 / 3.0
    else
      h = (r - g) * K + 2.0 / 3.0
    end
  end
  return h, M == 0.0 and 0.0 or C / M, M
end

function utils.hsv2rgb(h, s, v)
  local C = v * s
  local m = v - C
  local r, g, b = m, m, m
  if h == h then
    local h_ = (h % 1.0) * 6
    local X = C * (1 - math.abs(h_ % 2 - 1))
    C, X = C + m, X + m
    if h_ < 1 then
      r, g, b = C, X, m
    elseif h_ < 2 then
      r, g, b = X, C, m
    elseif h_ < 3 then
      r, g, b = m, C, X
    elseif h_ < 4 then
      r, g, b = m, X, C
    elseif h_ < 5 then
      r, g, b = X, m, C
    else
      r, g, b = C, m, X
    end
  end
  return r, g, b
end

function utils.darken(hex, darker_n)
  local result = "#"

  for s in hex:gmatch "[a-fA-F0-9][a-fA-F0-9]" do
    local bg_numeric_value = tonumber("0x" .. s) - darker_n

    if bg_numeric_value < 0 then
      bg_numeric_value = 0
    end

    if bg_numeric_value > 255 then
      bg_numeric_value = 255
    end

    result = result .. string.format("%2.2x", bg_numeric_value)
  end

  return result
end

function utils.lighten(hex, lighten_n)
  return utils.darken(hex, lighten_n * -1)
end

function utils.luminance(hex)
  local r, g, b = hex2rgb(hex)
  local luminance = (r * 0.2126) + (g * 0.7152) + (b * 0.0722)
  return luminance < (255 / 2)
end

function utils.highlightset(hi, set, defaults)
  local group = hi
  hi = utils.highlight(hi)
  if dict.isblank(hi) then
    if defaults then
      hi = defaults
    else
      return
    end
  end

  dict.each(set, function(attrib, transformer)
    if not hi[attrib] then
      return
    end

    if is_a.f(transformer) then
      hi[attrib] = transformer(hi[attrib])
      vim.cmd(sprintf("hi %s %s=%s", group, attrib, hi[attrib]))
    else
      hi[attrib] = transformer
      vim.cmd(sprintf("hi %s %s=%s", group, attrib, transformer))
    end
  end)

  return hi
end
