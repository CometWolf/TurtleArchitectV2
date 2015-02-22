table = setmetatable(
  {
    deepCopy = function(t)
      local copy = {}
      for k,v in pairs(t) do
        if type(v) == "table" and v ~= _G then
          copy[k] = table.deepCopy(v)
        else
          copy[k] = v
        end
      end
      return copy
    end
  },
  {
    __index = _G.table
  }
)