local matrix
matrix = {
  new = function(dimensions)
    return setmetatable(
      {
        
      },
      {
        __index = function(t,k)
          if type(k) == "number" then
            local dimension = dimensions-1
            if dimension <= 0 then
              return nil
            end
            t[k] = matrix.new(dimension)
            return t[k]
          end
        end
      }
    )
  end
}
return matrix 