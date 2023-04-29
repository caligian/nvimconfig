--- Multimethod implementation
-- @classmod multimethod
local utils = require "lua-utils.utils"
local dict = require "lua-utils.dict"
local array = require "lua-utils.array"
local class = require "lua-utils.class"
local types = require "lua-utils.types"
local exception = require "lua-utils.exception"
local validate = require "lua-utils.validate"
local is_a = validate.is_a
local multimethod = class 'multimethod'

--------------------------------------------------------------------------------
--- Raised when parameters' type signature is not recognized by method
multimethod.InvalidTypeSignatureException = exception(
  "InvalidTypeSignatureException",
  "no callable associated with type signature"
)

--- Raised when multiple type signatures match the param's signatures
multimethod.MultipleSignaturesException =
  exception("MultipleSignaturesException", "duplicate type signature found")

--------------------------------------------------------------------------------
-- Set signature for dispatch callable
-- @param f callable
-- @param ... type signatures
function multimethod:set(f, ...) self.sig[{ ... }] = f end

--- Get callable by signature
-- @param ... type signatures
-- @see validate.is
function multimethod:get(...)
  local match = multimethod.get_best_match(dict.keys(self.sig), { ... })
  return self.sig[match]
end

--- Constructor for multimethod
-- @return multimethod callable
function multimethod:init()
  self.sig = {}
  local function __call (...) return self:get(...)(...) end 
end

local function compare_sig(signature, params)
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

function multimethod:get_matches(params)
  local param_n = #params

  return array.grep(
    self.sig,
    function(sig) return array.all(compare_sig(sig, params)) end
  )
end

function multimethod:get_matches_with_distance(params)
  local signatures = self.sig
  local n = #params
  local found = self:get_matches(params)

  return array.sort(
    array.imap(found, function(idx, x)
      local dist = n - #x
      return { dist, x }
    end),
    function(x, y) return x[1] < y[1] end
  )
end

function multimethod:get_best_match(params)
  local signatures = self.sig
  local matches = self:get_matches_with_distance(params)
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

return multimethod
