require "core.BufferGroup.BufferGroup"
require 'core.utils.command'

local function listpools()
  return BufferGroup.listpools()
end

local buffergroup = command "BufferGroup"
buffergroup.InvalidInputException = exception "invalid input given"

buffergroup:add("new", function(args)
  local pool, group, event, pattern = unpack(args.fargs)
  pool = pool or "default"

  if not group or not pattern then
    user.InvalidInputException:throw(args.fargs)
  end

  event = event or "BufEnter"

  BufferGroup(group, event, pattern, pool):enable()
end, {
  nargs = '+',
  complete = listpools
})

buffergroup:add(
  'removePool',
  function (args) BufferGroup.removepool(args.fargs[1]) end,
  {nargs=1, complete=listpools}
)
