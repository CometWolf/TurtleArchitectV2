math = setmetatable(
  {
    round = function(num)
      return math.floor(num+0.5)
    end
  },
  {
    __index = _G.math
  }
)