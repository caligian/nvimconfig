local Timer = class "Timer"
Timer.status = {}

local uv = vim.loop

function Timer:get_due_in()
  local due_in = self.timer:get_due_in()
  return due_in == 0 and false or due_in
end

function Timer:is_running()
  return self:get_due_in()
end

function Timer:init(timeout, interval, callback, wrap_callback)
  self.timer = uv.new_timer()
  self.timeout = timeout
  self.interval = interval
  self.callback = wrap_callback and vim.schedule_wrap(callback) or callback
  return self
end

function Timer:track(name)
  Timer.status[name] = self
end

function Timer:start()
  return self.timer:start(self.timeout, self.interval, self.callback) == 0
end

function Timer:again()
  return self.timer:again() == 0
end

function Timer:delete()
  Timer.status[self] = nil
end

function Timer:set_repeat(interval)
  self.timer:set_interval(interval)
  self.interval = interval
end

function Timer:get_repeat()
  self.interval = self.timer:get_repeat()
  return self.interval
end

function Timer:stop()
  self.timer:stop()
end

class("Repeater", Timer)

function Repeater:init(interval, callback, wrap)
  Repeater:super()(self, interval, interval, callback, wrap)
end

class("Timeout", Timer)

function Timeout:init(timeout, callback, wrap)
  Timeout:super()(self, timeout, 0, callback, wrap)
end
