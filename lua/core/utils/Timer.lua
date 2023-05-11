--- Async timers powered by libuv
-- @classmod Timer
local Timer = class "Timer"

--- Contains timer instances hashed by name
-- @table Timer.status
Timer.status = {}

local uv = vim.loop

--- Get time due for the timer
function Timer:get_due_in()
  local due_in = self.timer:get_due_in()
  return due_in == 0 and false or due_in
end

-- Is timer running?
function Timer:is_running()
  return self:get_due_in()
end

--- Create a new timer. Constructor function
-- @param timeout timeout length
-- @param interval repeat interval
-- @param callback callback to run
-- @param wrap_callback .schedule_wrap callback?
-- @return self
function Timer:init(timeout, interval, callback, wrap_callback)
  self.timer = uv.new_timer()
  self.timeout = timeout
  self.interval = interval
  self.callback = wrap_callback and vim.schedule_wrap(callback) or callback
  return self
end

--- Save timer instance by name
function Timer:track(name)
  Timer.status[name] = self
end

--- Start timer
-- @return true on success, false otherwise
function Timer:start()
  return self.timer:start(self.timeout, self.interval, self.callback) == 0
end

--- Rerun the timer
-- @return true on success, false otherwise
function Timer:again()
  return self.timer:again() == 0
end

--- Dereference instance from Timer.status
function Timer:delete()
  Timer.status[self] = nil
end

--- Change timer interval
-- @param interval repeat interval
function Timer:set_repeat(interval)
  self.timer:set_interval(interval)
  self.interval = interval
end

--- Get repeat interval
-- @return number
function Timer:get_repeat()
  self.interval = self.timer:get_repeat()
  return self.interval
end

--- Stop timer
function Timer:stop()
  self.timer:stop()
end

return Timer
