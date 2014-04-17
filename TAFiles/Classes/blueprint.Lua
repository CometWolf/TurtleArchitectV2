local blueprint
blueprint = { --blueprint class
  new = function()
    return setmetatable(
      {
        [1] = class.layer.new(),
        colorSlots = class.matrix.new(2)
      },
      {
        __index = blueprint
      }
    )
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
      for nX=#blueprint[nL],1,-1 do
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
      if blankLayer and not disableTrimming then
        file:delete()
        blueprint[nL] = nil
      else
        file:write(fX)
      end
    end
    file:write"END"
    file:write(textutils.serialize(blueprint.colorSlots))
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
    blueprint.colorSlots = class.matrix.new(2,textutils.unserialize(read()))
    file.close()
    return blueprint
  end,
  size = function(t)
  --returns the amount of layers in the blueprint
    return #t
  end,
  copy = function(blueprint,x1,z1,x2,z2)
  --returns a blueprint copy, optional coordinates
    local x,z = {},{}
    if not (x1 and x2) then
      x.min,x.max = math.huge,math.huge
    else
      x.max = math.max(x1,x2)
      x.min = math.min(x1,x2)
    end
    if not (z1 and z2) then
      z.min,z.max = math.huge,math.huge
    else
      z.max = math.max(z1,z2)
      z.min = math.min(z1,z2)
    end
    local copy = blueprint:new()
    for i=1,#blueprint do
      copy[nL] = blueprint[i]:new()
      for nX,vX in pairs(blueprint[i]) do
        if nX >= x.min and nX <= x.max then
          copy[nL][nX] = vX:new()
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
  markBuilt = function(blueprint,x1,z1,x2,z2)
    --marks the blueprint as built, optionally just one area
    for i=1,#blueprint do
      blueprint[i]:markBuilt(x1,z1,x2,z2)
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
}
return blueprint