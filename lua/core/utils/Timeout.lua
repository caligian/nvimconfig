--- Create a timer that runs callback and stops after timeout delay
-- Inherits from: Timer
-- @classmod Timeout
local Timer = require "core.utils.Timer"
local Timeout = class("Timeout", Timer)

--- Constructor
-- @param timeout timeout to wait before running callback
-- @param callback callback to run
-- @param wrap .schedule_wrap callback?
-- @see Timer.init
-- @return self
function Timeout:init(timeout, callback, wrap)
  Timeout:super()(self, timeout, 0, callback, wrap)
end

return Timeout
