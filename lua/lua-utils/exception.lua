--- Class-based exceptions.
-- Very simple exception system that standardizes exception handling. 
-- Exceptions have 4 keys: reason, obj, traceback, name
-- The rationale behind this is that lua requires a .__tostring metamethod for
-- every table and that is cumbersome. This class helps you to dump the exception
-- message whilst also making it useful to pass around and inspect.
-- @classmod exception
local class = require "lua-utils.class"
local str = require "lua-utils.str"
local pprint = require "lua-utils.pprint"
local utils = require "lua-utils.utils"
local array = require "lua-utils.array"
local types = require "lua-utils.types"
local exception = class "exception"

--------------------------------------------------------------------------------
local function __tostring(self, obj, reason)
  obj = obj or ''
  reason = reason or ''
  local traceback = str.split(debug.traceback("", 3), "\n")

  array.shift(traceback, 2)

  if traceback then
    for i = 1, #traceback do
      traceback[i] = "  " .. str.trim(traceback[i])
    end
  end

  local show = setmetatable({
    reason = self.reason or reason,
    obj = tostring(obj),
    traceback = traceback,
    name = self.name,
  }, { __tostring = dump })

  return show
end

--- Get string representation of the exception
function exception:__tostring()
  return __tostring(self)
end

--- Throw exception if test is false
-- @param test boolean
-- @param obj object to use in message
-- @param reason reason to use in the message
function exception:raise_unless(test, obj, reason)
  if not test then exception(__tostring(self, obj, reason)) end
end

--- Throw exception if test is false
-- @param test boolean
-- @param obj object to use in message
-- @param reason reason to use in the message
function exception:throw_unless(test, obj, reason)
  self:raise_unless(test, obj, reason)
end

--- Throw exception if test is false
-- @param test boolean
-- @param obj object to use in message
-- @param reason reason to use in the message
function exception:assert(test, obj, reason) assert(test, self) end

--- Throw exception with object and reason
-- @param obj object to use in the exception
-- @param reason reason
function exception:raise(obj, reason) exception(self) end

--- Throw exception with object and reason
-- @param obj object to use in the exception
-- @param reason reason
function exception:throw(obj, reason) exception:raise(obj, reason) end

--- Create a new object
-- @usage
-- exception = require 'exception'
-- local e = exception('1_is_not_2', '1 is not 2')
-- e:throw_unless(1 == 2) -- {name = '1_is_not_2', reason = '1 is not 2'}
--
-- var = 123
-- local e = exception '123Error'
-- local ok, obj = pcall(e.throw, e, var, 'another runtime message')
-- print(obj.object) -- 123
--
-- -- thrown exception is a table with keys:
-- -- name: name of the exception
-- -- traceback: traceback during the exception
-- -- reason: short description of the exception
-- -- object: object thrown with the exception
--
-- @param name name of the exception
-- @param reason reason to show
-- @return self
function exception:init(name, reason)
  self.name = name
  self.reason = reason
end

return exception
