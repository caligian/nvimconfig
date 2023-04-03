require "utils.types"

function struct(spec)
  validate.spec("t", spec)

  return setmetatable({}, {
    __newindex = function(self, k, v)
      assert(spec[k], "unrequired key supplied " .. k)
      validate[k](spec[k], v)
      rawset(self, k, v)
    end,
    type = "struct",
  })
end
