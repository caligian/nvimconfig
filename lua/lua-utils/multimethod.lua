--- Multimethod implementation
-- @classmod multimethod
-- @alias mt
local utils = require "lua-utils.utils"
local dict = require "lua-utils.dict"
local array = require "lua-utils.array"
local class = require "lua-utils.class"
local types = require "lua-utils.types"
local exception = require "lua-utils.exception"
local validate = require "lua-utils.validate"
local is_a = validate.is_a
local mt = {}
local multimethod = setmetatable({}, mt)

--------------------------------------------------------------------------------
--- Raised when parameters' type signature is not recognized by method
multimethod.InvalidTypeSignatureException =
  exception("InvalidTypeSignatureException", "no callable associated with type signature")

--- Raised when multiple type signatures match the param's signatures
multimethod.MultipleSignaturesException =
  exception("MultipleSignaturesException", "duplicate type signature found")

--- Get a multimethod callable with .get and .set methods
-- @static
-- @usage
-- mm = multimethod()
-- mm = multimethod.new()
-- @see multimethod.get
-- @see multimethod.set
-- @treturn callable
function multimethod.new()
  return setmetatable({
    get = multimethod.get,
    set = multimethod.set,
    sig = {},
  }, {
    __call = function(self, ...)
      return self:get(...)(...)
    end,
  })
end

--- Set callable for type signature
-- @tparam callable f
-- @tparam any ... type specs
function multimethod:set(f, ...)
  self.sig[{ ... }] = f
end

--- Get callable for a type signature
-- @tparam any ... type specs
-- @treturn callable or throw error
function multimethod:get(...)
  local match = multimethod.get_best_match(dict.keys(self.sig), { ... })
  return self.sig[match]
end

function multimethod.compare_sig(signature, params)
  local status_i = 0
  local status = {}
  local sig_n = #signature
  local param_len = #params

  if param_len < sig_n then
    signature = array.slice(signature, 1, param_len)
    sig_n = sig_n - (sig_n - param_len)
  end

  for i = 1, sig_n do
    status[status_i + 1] = is_a(params[i], signature[i])
    status_i = status_i + 1
  end

  for i = status_i + 1, #params do
    status[i] = false
  end

  return status
end

function multimethod.get_matches(signatures, params)
  local param_n = #params

  return array.grep(signatures, function(sig)
    return array.all(multimethod.compare_sig(sig, params))
  end)
end

function multimethod.get_matches_with_distance(signatures, params)
  local n = #params
  local found = multimethod.get_matches(signatures, params)

  return array.sort(
    array.imap(found, function(idx, x)
      local dist = n - #x
      return { dist, x }
    end),
    function(x, y)
      return x[1] < y[1]
    end
  )
end

function multimethod.get_best_match(signatures, params)
  local matches = multimethod.get_matches_with_distance(signatures, params)
  local best = array.grep(matches, function(x)
    if x[1] == 0 then
      return x
    else
      return false
    end
  end)
  local best_n = #best
  local matches_n = #matches

  if matches_n == 0 then
    multimethod.InvalidTypeSignatureException:raise()
  elseif best_n > 1 then
    multimethod.MultipleSignaturesException:raise(matches)
  elseif best_n == 1 then
    return best[1][2]
  elseif matches_n > 1 then
    multimethod.MultipleSignaturesException:raise(matches)
  end

  return matches[1][2]
end

function mt:__call()
  return self.new()
end

return multimethod
