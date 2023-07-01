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

function class:dumpjson(dest, f) file.write(dest, self:tojson(f)) end

--------------------------------------------------
require "core.utils.aliased"
require "core.utils.module"
require "core.utils.nvim"
require "core.utils.misc"
require "core.utils.module"
require "core.utils.telescope"
require "core.utils.color"
require "core.utils.buffer"
require "core.utils.autocmd"
require "core.utils.process"
require "core.utils.plugin"
require "core.utils.filetype"
require "core.utils.font"

