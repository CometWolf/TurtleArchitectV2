local screenBuffer
screenBuffer = {
  new = function()
    local buffer
    buffer = setmetatable(
      {
        x = 1,
        y = 1,
        bColor = colors.black,
        tColor = colors.white,
        marker = " ",
        layer = 1,
        blink = false,
        changed = class.matrix.new(2),
      },
      {
        __index = function(t,k)
          if not screenBuffer[k] then
            if type(k) == "number" then
              for i = #t+1,k do
                t[i] = rawget(t,layer) or class.matrix.new(2)
              end
              buffer.layer = k
              return t[k]
            end
          end
          return screenBuffer[k]
        end
      }
    )
    return buffer
  end,
  setBackgroundColor = function(buffer,color)
    buffer.bColor = (
      type(color) == "number" and color 
      or colors[color] and colors[color]
      or colorKey[color] and colorKey[color]
    )
  end,
  setTextColor = function(buffer,color)
    buffer.tColor = (
      type(color) == "number" and color 
      or colors[color] and colors[color]
      or colorKey[color] and colorKey[color]
    )
  end,
  setMarker = function(buffer,marker)
    buffer.marker = marker or " "
  end,
  setLayer = function(buffer,layer)
    buffer.layer = layer or #buffer
  end,
  setCursorPos = function(buffer,x,y)
    buffer.x = math.min(tTerm.screen.x,(x or buffer.x))
    buffer.y = math.min(tTerm.screen.y, (y or buffer.y))
  end,
  getCursorPos = function(buffer)
    return buffer.x,buffer.y
  end,
  setCursorBlink = function(buffer,BOOL)
    buffer.blink = BOOL
    term.setCursorBlink(BOOL)
  end,
  getTextColor = function(buffer)
    return buffer.tColor
  end,
  getBackgroundColor = function(buffer)
    return buffer.bColor
  end,
  getBlink = function(buffer)
    return buffer.blink
  end,
  getTop = function(buffer,x,y,from)
    for iL = (from or #buffer),1,-1 do
      if buffer[iL][x][y] then
        return iL
      end
    end
  end,
  write = function(buffer,text,bColor,tColor)
    for character in string.gmatch(text,".") do
      if buffer.x > tTerm.screen.x then
        return
      end
      local p = buffer[buffer.layer][buffer.x][buffer.y]
      if not p
      or p.marker ~= character
      or p.bColor ~= buffer.bColor
      or p.tColor ~= buffer.tColor and character ~= " " then
        buffer[buffer.layer][buffer.x][buffer.y] = {
          bColor = buffer.bColor,
          tColor = buffer.tColor,
          marker = character,
        }
        if buffer.layer == buffer:getTop(buffer.x,buffer.y) then
          buffer.changed[buffer.x][buffer.y] = buffer.layer
        end
      end
      buffer.x = buffer.x+1
    end
  end,
  clearLine = function(buffer)
    buffer:setCursorPos(1,buffer.y)
    buffer:write(string.rep(" ",tTerm.screen.x))
  end,
  clear = function(buffer)
    for iL = #buffer,1 do
      buffer:del(iL)
    end
  end,
  fill = function(buffer,color)
    buffer.bColor = color or buffer.bColor
    for iY = 1,tTerm.screen.y do
      buffer:setCursorPos(1,iY)
      buffer:write(string.rep(" ",tTerm.screen.x))
    end
  end,
  drawPoint = function(buffer,x,y,color,marker)
    marker = marker or buffer.marker
    color = color or buffer.bColor
    local p = buffer[buffer.layer][x][y]
    if not p
    or p.bColor ~= color
    or p.tColor ~= color and marker and marker ~= " "
    or marker and p.marker ~= marker then
      buffer[buffer.layer][x][y] = {
        bColor = color,
        tColor = color,
        marker = marker
      }
      if buffer.layer == buffer:getTop(x,y) then
        buffer.changed[x][y] = buffer.layer
      end
    end
  end,
  drawLine = function(buffer,x1,y1,x2,y2,color,marker)
    local x = {
      max = math.min(tTerm.screen.x,math.max(x1,x2)),
      min = math.max(1,math.min(x1,x2))
    }
    local y = {
      max = math.min(tTerm.screen.y,math.max(y1,y2)),
      min = math.max(1,math.min(y1,y2))
    }
    marker = marker or " "
    color = color or buffer.bColor
    for iX = x.min,x.max do
      for iY = y.min,y.max do
        local p = buffer[buffer.layer][iX][iY]
        if not p
        or p.bColor ~= color
        or p.tColor ~= color and marker ~= " "
        or p.marker ~= marker then
          buffer[buffer.layer][iX][iY] = {
            bColor = color,
            tColor = color,
            marker = marker
          }
          if buffer.layer == buffer:getTop(iX,iY) then
            buffer.changed[iX][iY] = buffer.layer
          end
        end
      end
    end
  end,
  drawBox = function(buffer,x1,y1,x2,y2,color,marker)
    for iX = x1,x2 do
      buffer:drawLine(iX,y1,iX,y2,color,marker)
    end
  end,
  drawFrame = function(buffer,x1,y1,x2,y2,color,marker)
    buffer:drawLine(x1,y1,x2,y1,color,marker)
    buffer:drawLine(x2,y1,x2,y2,color,marker)
    buffer:drawLine(x2,y2,x1,y2,color,marker)
    buffer:drawLine(x1,y2,x1,y1,color,marker)
  end,
  add = function(buffer,num)
    table.insert(buffer,class.matrix.new(2),num)
  end,
  delLayer = function(buffer,layer)
    layer = layer or #buffer
    if layer == #buffer then
      for nX,vX in pairs(buffer[layer]) do
        for nY,vY in pairs(vX) do
          buffer.changed[nX][nY] = buffer:getTop(nX,nY,layer-1)
        end
      end
    else
      for nX,vX in pairs(buffer[layer]) do
        for nY,vY in pairs(vX) do
          if buffer:getTop(nX,nY) == layer then
            buffer.changed[nX][nY] = buffer:getTop(nX,nY,layer-1)
          end
        end
      end
    end
    table.remove(buffer,layer)
  end,
	clearLayer = function(buffer,layer)
    layer = layer or #buffer
    if layer == #buffer then
      for nX,vX in pairs(buffer[layer]) do
        for nY,vY in pairs(vX) do
          buffer.changed[nX][nY] = buffer:getTop(nX,nY,layer-1)
        end
      end
    else
      for nX,vX in pairs(buffer[layer]) do
        for nY,vY in pairs(vX) do
          if buffer:getTop(nX,nY) == layer then
            buffer.changed[nX][nY] = buffer:getTop(nX,nY,layer-1)
          end
        end
      end
    end
    buffer[layer] = class.layer.new(2)
	end,
  delPoint = function(buffer,x,y,layer)
    layer = layer or buffer.layer
    if layer == #buffer
    or buffer:getTop(x,y) == layer then
      buffer.changed[x][y] = buffer:getTop(x,y,layer-1)
    end
    buffer[layer][x][y] = nil
  end,
  refresh = function(buffer)
    for x,vX in pairs(buffer.changed) do
      for y,layer in pairs(vX) do
        local c = buffer[layer][x][y]
        term.setCursorPos(x,y)
        term.setBackgroundColor(c.bColor)
        term.setTextColor(c.tColor)
        term.write(c.marker)
      end
    end
    buffer:glassRefresh()
    buffer.changed = class.matrix.new(2)
    if buffer.blink then
      term.setTextColor(buffer.tColor)
      term.setCursorPos(buffer:getCursorPos())
    end
  end,
  redraw = function(buffer)
    for iX = 1,tTerm.screen.x do
      for iY = 1,tTerm.screen.y do
        local c = buffer[buffer:getTop(iX,iY)][iX][iY]
        term.setCursorPos(iX,iY)
        term.setBackgroundColor(c.bColor)
        term.setTextColor(c.tColor)
        term.write(c.marker)
      end
    end
    buffer:glassRedraw()
  end,
  glassInit = function(buffer,bridge,sizeX,sizeY)
    bridge.clear()
    buffer.glass = {
      pixel = class.matrix.new(2),
      text = class.matrix.new(2)
    }
    for iX = 1,tTerm.screen.x do
      for iY = 1,tTerm.screen.y do
        buffer.glass.pixel[iX][iY] = bridge.addBox(iX*sizeX,iY*sizeY,sizeX,sizeY)
        buffer.glass.text[iX][iY] = bridge.addText(iX*sizeX,iY*sizeY," ")
        buffer.glass.text[iX][iY].setScale(math.floor(((sizeX+sizeY)/2))/8)
      end
    end
  end,
  glassResize = function(buffer,x,y)
    glasses.size.x = x
    glasses.size.y = y
    for iX = 1,tTerm.screen.x do
      for iY = 1,tTerm.screen.y do
        local pixel = buffer.glass.pixel[iX][iY]
        pixel.setHeight(y)
        pixel.setWidth(x)
        pixel.setX(iX*x)
        pixel.setY(iY*y)
        local text = buffer.glass.text[iX][iY]
        text.setScale(math.floor(((x+y)/2))/8)
        text.setX(iX*x)
        text.setY(iY*y)
      end
    end
  end,
  glassRedraw = function(buffer)
    if not buffer.glass then
      return
    end
    for iX = 1,tTerm.screen.x do
      for iY = 1,tTerm.screen.y do
        buffer.glass.pixel[iX][iY].setColor(glasses.colors[buffer[buffer:getTop(iX,iY)][iX][iY].bColor])
      end
    end
  end,
  glassRefresh = function(buffer)
    if not buffer.glass then
      return
    end
    for x,vX in pairs(buffer.changed) do
      for y,layer in pairs(vX) do
        buffer.glass.pixel[x][y].setColor(glasses.colors[buffer[layer][x][y].bColor])
        buffer.glass.text[x][y].setText(buffer[layer][x][y].marker)
        buffer.glass.text[x][y].setColor(glasses.colors[buffer[layer][x][y].tColor])
      end
    end
  end
}
return screenBuffer