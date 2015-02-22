string = setmetatable(
  {
    gfind = function(sString,pattern)
      --returns a table of pattern occurrences in a string
      local tRes = {}
      local point = 1
      while point <= #sString do
        tRes[#tRes+1],point = sString:find(pattern,point)
        if not point then
          break
        else
          point = point+1
        end
      end
      return tRes
    end,
    lineFormat = function(text,lineLength,center)
      local tLines = {}
      while #text > 0 do  --splits text into a table containing each line
        local line = text:sub(1,lineLength)
        local newLine = string.find(line.."","\n") --check for new line character
        if newLine then
          line = line:sub(1,newLine-1)
          text = text:sub(#line+2,#text)
        elseif #line == lineLength then
          local endSpace = line:find"%s$" or line:find"%s%S-$" or lineLength
          line = line:sub(1,endSpace)
          text = text:sub(#line+1)
        else
          text = ""
        end
        if center then
          line = string.rep(" ",math.max(math.floor((lineLength-#line)/2),0))..line
          line = line..string.rep(" ",math.max(lineLength-#line,0))
        end
        tLines[#tLines+1] = line
      end
      return tLines
    end
  },
  {
    __index = _G.string
  }
)