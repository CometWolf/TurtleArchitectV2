local layer
layer = { --layer class
  new = function(data)
    return setmetatable(
      data or {},
      {
        __index = function(t,k)
          if not layer[k] then
            t[k] = class.x.new()
            return t[k]
          end
          return layer[k]
        end,
        __metatable = false
      }
    )
  end,
  size = function(layer,dir)
    local x,z = 0,0
    for nX,vX in pairs(layer) do
      x = math.max(nX,x)
      for nZ in pairs(vX) do
        z = math.max(nZ,z)
      end
    end
    return dir == "x" and x or dir == "z" and z or x,z
  end,
  copy = function(layer,x1,z1,x2,z2,clipboard)
  --returns a layer copy, optional coordinates
    local copy = layer.new()
    local x,z = {},{}
    if not (x1 and x2) then
      x.min,x.max = 1,layer:size("x")
    else
      x.max = math.max(x1,x2)
      x.min = math.min(x1,x2)
    end
    if not (z1 and z2) then
      z.min,z.max = 1,math.huge
    else
      z.max = math.max(z1,z2)
      z.min = math.min(z1,z2)
    end
    local eZ = 1
    for nX = x.min,x.max do
      local vX = layer[nX]
      nX = nX-x.min+1
      copy[nX] = vX.new()
      for nZ,vZ in pairs(vX) do
        if nZ >= z.min and nZ <= z.max then
          copy[nX][nZ-z.min+1] = vZ ~= " " and vZ or nil
          eZ = math.max(eZ,nZ)
        end
      end
    end
    if clipboard then
      return {
        l = copy,
        sX = x.min,
        eX = x.max,
        sZ = z.min,
        eZ = eZ,
        lX = x.max-x.min+1,
        lZ = eZ-z.min+1,
      }
    end
    return copy
  end,
  paste = function(layer,clipboard,pX,pZ,merge)
    --combines layers, with an optional offset
    pX = pX and pX-1 or 0
    pZ = pZ and pZ-1 or 0
    for nX,vX in pairs(clipboard) do
      for nZ,vZ in pairs(vX) do
        if merge then
          if layer[nX+pX][nZ+pZ] == " " then
            layer[nX+pX][nZ+pZ] = vZ
          end
        else
          layer[nX+pX][nZ+pZ] = vZ
        end
      end
    end
  end,
  markBuilt = function(layer,x1,z1,x2,z2,clearBreak)
    --marks the layer as built, optionally just one area
    local x,z = {},{}
    if not (x1 and x2) then
      x.min,x.max = 1,layer:size("x")
    else
      x.max = math.max(x1,x2)
      x.min = math.min(x1,x2)
    end
    if not (z1 and z2) then
      z.min,z.max = 1,math.huge
    else
      z.max = math.max(z1,z2)
      z.min = math.min(z1,z2)
    end
    for nX = x.min,x.max do
      local vX = layer[nX]
      for nZ,vZ in pairs(vX) do
        if nZ >= z.min and nZ <= z.max then
          vX[nZ] = clearBreak and vZ == "X" and " " or vZ:upper()
        end
      end
    end
  end,
  markUnbuilt = function(layer,x1,z1,x2,z2)
    --marks the layer as unbuilt, optionally just one area
    local x,z = {},{}
    if not (x1 and x2) then
      x.min,x.max = 1,layer:size("x")
    else
      x.max = math.max(x1,x2)
      x.min = math.min(x1,x2)
    end
    if not (z1 and z2) then
      z.min,z.max = 1,math.huge
    else
      z.max = math.max(z1,z2)
      z.min = math.min(z1,z2)
    end
    for nX = x.min,x.max do
      local vX = layer[nX]
      for nZ,vZ in pairs(vX) do
        if nZ >= z.min and nZ <= z.max then
          vX[nZ] = vZ:lower()
        end
      end
    end
  end,
  flipX = function(layer,x1,z1,x2,z2)
  --flips layer on the x-axis, optionally just one area
    local x,z = {},{}
    if not (x1 and x2) then
      x.min,x.max = 1,layer:size("x")
      x.size = x.max+1
    else
      x.max = math.max(x1,x2)
      x.min = math.min(x1,x2)
      x.size = x.max+1
    end
    if not (z1 and z2) then
      z.min,z.max = 1,math.huge
    else
      z.max = math.max(z1,z2)
      z.min = math.min(z1,z2)
    end
    local flipped = layer.new()
    for nX = x.min,x.max do
      local vX = layer[nX]
      nX = x.size-nX
      flipped[nX] = vX.new()
      for nZ,vZ in pairs(vX) do
        if nZ >= z.min and nZ <= z.max then
          flipped[nX][nZ] = vZ
        end
      end
    end
    return flipped
  end,
  flipZ = function(layer,x1,z1,x2,z2)
  --flips layer on the Z-axis, optionally just one area
    local x,z = {},{}
    if not (x1 and x2) then
      x.min,x.max = 1,layer:size("x")
    else
      x.max = math.max(x1,x2)
      x.min = math.min(x1,x2)
    end
    if not (z1 and z2) then
      z.min,z.max = 0,math.huge
      z.size = 0
      for nX,vX in pairs(layer) do
        z.size = math.max(z.size,vX:size())
      end
      z.size = z.size+1
    else
      z.max = math.max(z1,z2)
      z.min = math.min(z1,z2)
      z.size = z.max+1
    end
    local flipped = layer.new()
    for nX = x.min,x.max do
      local vX = layer[nX]
      flipped[nX] = vX.new()
      for nZ,vZ in pairs(vX) do
        if nZ >= z.min and nZ <= z.max then
          flipped[nX][z.size-nZ] = vZ
        end
      end
    end
    return flipped
  end,
  recolor = function(layer,color,x1,z1,x2,z2)
  --changes all colored blocks to the specified color, optionally within an area
    local x,z = {},{}
    if not (x1 and x2) then
      x.min,x.max = 1,layer:size("x")
    else
      x.max = math.max(x1,x2)
      x.min = math.min(x1,x2)
    end
    if not (z1 and z2) then
      z.min,z.max = 1,math.huge
    else
      z.max = math.max(z1,z2)
      z.min = math.min(z1,z2)
    end
    local loopLayer = layer:copy()
    for nX = x.min,x.max do
      for nZ,vZ in pairs(loopLayer[nX]) do
        if nZ >= z.min and nZ <= z.max then
          layer[nX][nZ] = color
        end
      end
    end
  end,
  delete = function(layer,sX,sZ,eX,eZ)
  --clears the specified area
    for iX = math.min(sX,eX),math.max(eX,sX) do
      for iZ = math.min(sZ,eZ),math.max(eZ,sZ) do
        layer[iX][iZ] = nil
      end
    end
  end,
  render = function(layer)
  --renders the layer on the canvas
    local view = tTerm.viewable
  	local mX = view.mX
    local mZ = view.mZ
    screen:setLayer(screen.layers.canvas)
    local scrX = tTerm.scroll.x
    local scrZ = tTerm.scroll.z
    for x = view.sX,view.eX do
      for z = view.sZ,view.eZ do
        screen:setCursorPos(x-scrX+mX,z-scrZ+mZ)
        writePoint(x,z)
      end
    end
  end
}
return layer