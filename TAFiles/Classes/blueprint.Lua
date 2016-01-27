local blueprint
blueprint = { --blueprint class
  new = function(data,auto)
    data = data or {}
    data[1] = class.layer.new(data[1])
    data.orientation = data.orientation or "Y"
    data.colorSlots = class.matrix.new(2,data.colorSlots)
    if auto then
      return setmetatable(
        data,
        {
          __index = function(t,k)
            if type(k) == "number" then
              for i=#t+1,k do
                t[i] = class.layer.new()
              end
              return t[k]
            else
              return blueprint[k]
            end
          end,
          __metatable = false
        }
      )
    else
      return setmetatable(
        data,
        {
          __index = blueprint,
          __metatable = false
        }
      )
    end
  end,
  save = function(blueprint,path,disableTrimming)
  --saves the blueprint to the specified path
    local file = class.fileTable.new()
    file:write("Blueprint file for CometWolf's Turtle Architect. Pastebin code: "..tPaste.program)
    local blankLayer = true
    for nL=#blueprint,1,-1 do
      local blankX = true
      file:write("L"..nL)
      local fX = class.fileTable.new()
      for nX=class.layer.size(blueprint[nL],"x"),1,-1 do
        local sX = ""
        for nZ,vZ in pairs(blueprint[nL][nX]) do
          if #sX < nZ then
            sX = sX..string.rep(" ",nZ-#sX-1)..vZ
          else
            sX = sX:sub(1,nZ-1)..vZ..sX:sub(nZ+1)
          end
          if blankX and vZ ~= " " then
            blankX = false
            blankLayer = false
          end
        end
        if blankX and not disableTrimming then
          blueprint[nL][nX] = nil
        else
          fX:write(sX,nX)
        end
      end
      if blankLayer and not disableTrimming and nL > 1 then
        file:delete()
        blueprint[nL] = nil
      else
        file:write(fX)
      end
    end
    file:write"END"
    file:write("Orientation: "..blueprint.orientation)
    file:write((textutils.serialize(blueprint.colorSlots):gsub("\n%s-","")))
    if path == true then
      return file:readAll()
    end
    file:save(path..".TAb")
  end,
  load = function(path)
  --loads the blueprint from the specified path
    local file
    if type(path) == "table" then
      local curLine = 1
      file = {
        readLine = function()
          curLine = curLine+1
          return path[curLine-1]
        end,
        close = function()
          path = nil
        end
      }
    else
      path = path..".TAb"
      if not fs.exists(path) then
        return false
      end
      file = fs.open(path,"r")
    end
    read = file.readLine
    if read() ~= "Blueprint file for CometWolf's Turtle Architect. Pastebin code: "..tPaste.program then
      file.close()
      return false
    end
    local blueprint = class.blueprint.new()
    local line = read()
    while line and line:match"L%d+" do
      local layer = tonumber(line:match"%d+")
      blueprint[layer] = class.layer.new()
      line = read()
      local x = 0
      while line and not line:match"L%d" and line ~= "END" do
        x = x+1
        blueprint[layer][x] = class.x.new()
        local tPoints = string.gfind(line,"%S")
        for k,z in pairs(tPoints) do
          blueprint[layer][x][z] = line:sub(z,z)
        end
        line = read()
      end
    end
    local line = read()
    blueprint.orientation = line:match"Orientation: ([XYZ])$"
    if not blueprint.orientation then
      blueprint.orientation = "Y"
    else
      line = read()
    end
    blueprint.colorSlots = class.matrix.new(2,(textutils.unserialize(line or "{}")))
    file.close()
    return blueprint
  end,
  size = function(blueprint)
  --returns the amount of layers and the dimensions of the blueprint
    local x = 0
    local z = 0
    for iL,vL in ipairs(blueprint) do
      local lX,lZ = vL:size()
      x = math.max(x,lX)
      z = math.max(z,lZ)
    end
    return #blueprint,x,z
  end,
  copy = function(cBlueprint,x1,z1,x2,z2)
  --returns a blueprint copy, optional coordinates
    local x,z = {},{}
    if not (x1 and x2) then
      x.min,x.max = 1,math.huge
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
    local copy = blueprint.new({colorSlots = table.deepCopy(cBlueprint.colorSlots)})
    for nL=1,#cBlueprint do
      copy[nL] = class.layer.new()
      for nX,vX in pairs(cBlueprint[nL]) do
        if nX >= x.min and nX <= x.max then
          copy[nL][nX] = class.x.new()
          for nZ,vZ in pairs(vX) do
            if nZ >= z.min and nZ <= z.max then
              copy[nL][nX][nZ] = vZ
            end
          end
        end
      end
    end
    return copy
  end,
  paste = function(blueprint,clipboard,pX,pZ,merge)
    --combines blueprint, with an optional offset
    pX = pX and pX-1 or 1
    pZ = pZ and pZ-1 or 1
    while #blueprint < #clipboard do
      blueprint[#blueprint+1] = class.layer.new()
    end
    for nL = 1,#clipboard do
      blueprint[nL]:paste(clipboard[nL],pX,pZ,merge)
    end
  end,
  markBuilt = function(blueprint,x1,z1,x2,z2,clearBreak)
    --marks the blueprint as built, optionally just one area
    for i=1,#blueprint do
      blueprint[i]:markBuilt(x1,z1,x2,z2,clearBreak)
    end
  end,
  markUnbuilt = function(blueprint,x1,z1,x2,z2)
    --marks the blueprint as unbuilt, optionally just one area
    for i=1,#blueprint do
      blueprint[i]:markUnbuilt(x1,z1,x2,z2)
    end
  end,
  flipX = function(blueprint,x1,z1,x2,z2)
  --flips blueprint on the x-axis, optionally just one area
    for i=1,#blueprint do
      blueprint[i] = blueprint[i]:flipX(x1,z1,x2,z2)
    end
  end,
  flipZ = function(blueprint,x1,z1,x2,z2)
  --flips blueprint on the Z-axis, optionally just one area
    for i=1,#blueprint do
      blueprint[i] = blueprint[i]:flipZ(x1,z1,x2,z2)
    end
  end,
  rotate = function(blueprint,axis)
    if blueprint.orientation == axis then
      return blueprint
    end
    local rotated = class.blueprint.new()
    local y,x,z = blueprint:size()
    if axis == "Y" then
      if blueprint.orientation == "X" then --X to Y
        for iX = 1,x do
          rotated[iX] = class.layer.new()
          for iY,vL in ipairs(blueprint) do
            rotated[iX][iY] = vL[iX]
          end
        end
      else --Z to Y
        for iZ = 1,z do
          rotated[iZ] = class.layer.new()
          local rL = rotated[iZ]
          for iY,vY in ipairs(blueprint) do
            for iX,vX in pairs(vY) do
              rL[iX][iY] = vX[iZ]
            end
          end
        end
      end
    elseif axis == "X" then
      if blueprint.orientation == "Y" then --Y to X
        for iX = 1,x do
          rotated[iX] = class.layer.new()
          local rL = rotated[iX]
          for iY,vL in ipairs(blueprint) do
            rL[iY] = vL[iX]
          end
        end
      else --Z to X
        for iY,vY in ipairs(blueprint) do
          rotated[iY] = class.layer.new()
          for iX,vX in pairs(vY) do
            for iZ,vZ in pairs(vX) do 
              rotated[iY][iZ][iX] = vZ
            end
          end
        end
      end
    elseif axis == "Z" then
      if blueprint.orientation == "X" then --X to Z
        for iY,vY in ipairs(blueprint) do
          rotated[iY] = class.layer.new()
          for iX,vX in pairs(vY) do
            for iZ,vZ in pairs(vX) do 
              rotated[iY][iZ][iX] = vZ
            end
          end
        end
      else --Y to Z
        for iZ = 1,z do
          rotated[iZ] = class.layer.new()
          local rL = rotated[iZ]
          for iY,vY in ipairs(blueprint) do
            for iX,vX in pairs(vY) do
              rL[iX][iY] = vX[iZ]
            end
          end
        end
      end
    end
    rotated.orientation = axis
    return rotated
  end
}
return blueprint
