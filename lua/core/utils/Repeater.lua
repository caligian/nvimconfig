--- Create a timer running at fixed intervals
-- @classmod Repeater
local Timer = require "core.utils.Timer"
local Repeater = class("Repeater", Timer)

--- Constructor function
-- @param interval repeat interval
-- @param callback callback to run
-- @param wrap .schedule_wrap callback?
-- @see Timer.init
-- @return self
function Repeater:init(interval, callback, wrap)
  Repeater:super()(self, interval, interval, callback, wrap)
end

return Repeater
