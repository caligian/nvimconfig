--- Add serialization to classes

function class:tojson(f)
  local out = {}

  for key, value in pairs(self:todict()) do
    if f then
      out[key] = f(key, value)
    elseif not is_callable(value) then
      out[key] = value
    end
  end

  return json.encode(out)
end

function class:dumpjson(dest, f)
  file.write(dest, self:tojson(f))
end

--------------------------------------------------
require "core.utils.aliased"
require "core.utils.module"
require "core.utils.nvim"
require "core.utils.misc"
require "core.utils.telescope"
require "core.utils.color"

--------------------------------------------------
-- API
require "core.utils.Autocmd"
require "core.utils.Augroup"
require "core.utils.Keybinding"
require "core.utils.Buffer"
require "core.utils.Term"
require "core.utils.Process"

--------------------------------------------------------------------------------
-- Framework utils
require "core.utils.Filetype"
