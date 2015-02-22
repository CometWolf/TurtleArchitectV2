local x 
x = { --x-axis class
  new = function()
    return setmetatable(
      {

      },
      {
        __index = function(t,k)
          if not x[k] then
            assert(type(k) == "number","Error: Attempt to access non-number value "..k.." on z-axis")
            return " "
          end
          return x[k]
        end,
        __metatable = false
      }
    )
  end,
  size = function(t)
    local z = 0
    for nZ in pairs(t) do
      z = math.max(z,nZ)
    end
    return z
  end
}
return x
