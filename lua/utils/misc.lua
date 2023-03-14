-- Will not work with userdata
function whereis(bin, regex)
  local out = vim.fn.system("whereis " .. bin .. [[ | cut -d : -f 2- | sed -r "s/(^ *| *$)//mg"]])
  out = trim(out)
  out = split(out, " ")

  if isblank(out) then
    return false
  end

  if regex then
    for _, value in ipairs(out) do
      if value:match(regex) then
        return value
      end
    end
  end
  return out[1]
end

-- For multiple patterns, OR matching will be used
-- If varname in [varname] = var is prefixed with '!' then it will be overwritten
function global(vars)
  for var, value in pairs(vars) do
    if var:match "^!" then
      var = var:gsub("^!", "")
      _G[var] = value
    elseif _G[var] == nil then
      _G[var] = value
    end
    globals[var] = value
  end
end

function with_open(fname, mode, callback)
  local fh = io.open(fname, mode)
  local out = nil
  if fh then
    out = callback(fh)
    fh:close()
  end

  return out
end

function joinpath(...)
  return table.concat({ ... }, "/")
end

function basename(s)
  s = vim.split(s, "/")
  return s[#s]
end
