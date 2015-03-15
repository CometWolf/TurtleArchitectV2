function saveProgress(fileName,tProgress)
  local file = class.fileTable.new()
  file:write("layers: "..textutils.serialize(tProgress.layers):gsub("\n%s-",""))
  file:write("X: "..tProgress.x)
  file:write("Y: "..tProgress.y)
  file:write("Z: "..tProgress.z)
  file:write("dir X: "..tProgress.dir.x)
  file:write("dir Y: "..tProgress.dir.y)
  file:write("dir Z: "..tProgress.dir.z)
  file:write("Enderchest: "..(tProgress.enderChest or "Disabled"))
  file:write("Break mode: "..(tProgress.breakMode and "Enabled" or "Disabled"))
  file:save(fileName..".TAo")
end

function loadProgress(fileName)
  local tOngoing = {}
  local file = fs.open(fileName..".TAo","r")
  local read = file.readLine
  local line = read()
  tOngoing.layers = textutils.unserialize(line:match"layers: ({.+)" or 1)
  line = read()
  tOngoing.x = tonumber(line:match"X: ([%d-]+)" or 0)
  line = read()
  tOngoing.y = tonumber(line:match"Y: ([%d-]+)" or 0)
  line = read()
  tOngoing.z = tonumber(line:match"Z: ([%d-]+)" or 0)
  tOngoing.dir = {}
  line = read()
  tOngoing.dir.x = line:match"dir X: ([+-])" or "+"
  line = read()
  tOngoing.dir.y = line:match"dir Y: ([+-])" or "+"
  line = read()
  tOngoing.dir.z = line:match"dir Z: ([+-])" or "+"
  line = read()
  tOngoing.enderChest = tonumber(line:match"Enderchest: (%d+)") or false
  line = read()
  tOngoing.breakMode = (line:match"Break mode: (.+)" == "Enabled")
  file.close()
  return tOngoing
end

function selectColor(color,threshold)
  --checks the slots assigned to (color) for blocks,
  --and acts accordingly
  threshold = threshold or 0 --min amount of items in accepted slot
  while true do
    for k,v in pairs(tBlueprint.colorSlots[color]) do
      if turtle.getItemCount(v) >= threshold then
        turtle.select(v)
        return true
      end
    end
    if cTurtle.tSettings.enderFuel then
      if cTurtle.enderRestock(cTurtle.tSettings.enderFuel,tBlueprint.colorSlots[color],tBlueprint.colorSlots[color]) then
        turtle.select(tBlueprint.colorSlots[color][1])
        return true
      end
    end
    local retry = tTimers.restockRetry.start()
    if tMode.sync.amount > 0 then
      rednet.send(tMode.sync.ids,"Turtle status",{type = "Blocks required",color = color, slots = tBlueprint.colorSlots[color][1].."-"..tBlueprint.colorSlots[color][#tBlueprint.colorSlots[color]]})
    end
    local button,tRes = window.text(
      keyColor[color].." blocks required in slots "..tBlueprint.colorSlots[color][1].."-"..tBlueprint.colorSlots[color][#tBlueprint.colorSlots[color]],
      {
        "Cancel",
        "Ok"
      },
      false,
      {
        timer = function(tEvent)
          if tEvent[2] == retry then
            return "Ok"
          end
        end,
        modem_message = function(tEvent)
          if tEvent[3] == modemChannel
          and type(tEvent[5]) == "table"
          and tEvent[5].rID[os.id] then
            local data = tEvent[5]
            local event = data.event
            local senderId = data.sID
            local type = data.type
            if event == "Turtle command"
            and type == "Restock" then
              return "Ok"
            end
          end
        end
      }
    )
    if button == "Cancel" then
      return false
    end
  end
end

function checkUsage(blueprint,tLayers)
  --checks amount of materials required to build the given blueprint
  blueprint = blueprint or tBlueprint
  if not tOngoing.layers then
    tOngoing.layers = {}
    for i=1,#tBlueprint do
      tOngoing.layers[i] = i
    end
  end
  local tUsage = {
    fuel = 0
  }
  local tPos = {
    x = 0,
    y = 1,
    z = 0
  }
  local placed = class.matrix.new(3)
  local loop = 0
  for iL,nL in ipairs(tLayers) do
    for nX,vX in pairs(blueprint[nL]) do
      for nZ,block in pairs(vX) do
        local nX = nX
        while block do
          if block:match"[%lX]"
          and not placed[nL][nX][nZ] then
            tUsage.fuel = math.abs(nX-tPos.x+math.abs(nZ-tPos.z))+tUsage.fuel
            tPos.z = nZ
            tPos.x = nX
            tUsage[block] = (tUsage[block] or 0)+1
            placed[nL][nX][nZ] = true
          end
          block = nil
          local nextBlock = {}
          for i=-1,1 do --scan for blocks in vicinity
            for j=-1,1 do
              if blueprint[nL][nX+i][nZ+j]:match"[X%l]"
              and not placed[nL][nX+i][nZ+j] then
                nextBlock = {
                  b = blueprint[nL][nX+i][nZ+j],
                  nX = nX+i,
                  nZ = nZ+j
                }
                if j == 0
                or i == 0 then --1 block away, diagonal blocks are second priority
                  block = nextBlock.b
                  break
                end
              end
              if block then
                break
              end
            end
            if block then
              break
            end
          end
          block = block or nextBlock.b
          nX = nextBlock.nX
          nZ = nextBlock.nZ
        end
      end
    end
    tUsage.fuel = math.abs(nL-tPos.y)+tUsage.fuel
    tPos.y = nL
    loop = loop+1
    if loop%10 == 0 then
      sleep(0.05)
    end
  end
  return tUsage
end

function assignColorSlots(color)
  local tSelection = {}
  for iS = 1,16 do
    tSelection[iS] = {}
    local selection = tSelection[iS]
    selection.text = tostring(iS)
    for iC,v in ipairs(tBlueprint.colorSlots[color]) do
      if v == iS then
        selection.selected = true
        break
      end
    end
  end
  local button, tRes = window.scroll(
    "Select slots for "..keyColor[color],
    tSelection,
    true
  )
  if button ~= "Cancel" then
    table.sort(tRes)
    tBlueprint.colorSlots[color] = {}
    for i,slot in ipairs(tRes) do
      tBlueprint.colorSlots[color][i] = tonumber(slot)
    end
    return true
  end
  return false
end

function checkProgress(fileName,tProgress,blueprint,auto)
  blueprint = blueprint or class.blueprint.load(fileName) or tBlueprint
  if fileName
  and fs.exists(fileName..".TAo")
  and not tProgress then
    tProgress = loadProgress(fileName)
    if auto then
      return tProgress
    else
      local button = window.text(
        [[In-progress build of current blueprint found.
layers ]]..tProgress.layers[1]..[[-]]..tProgress.layers[#tProgress.layers]..[[ 
X: ]]..tProgress.x..[[ "]]..tProgress.dir.x..[["
Y: ]]..tProgress.y..[[ "]]..tProgress.dir.y..[["
Z: ]]..tProgress.z..[[ "]]..tProgress.dir.z..[["
Break mode: ]]..(tProgress.breakMode and "ON" or "OFF")..[[ 
Enderchest: ]]..(tProgress.enderChest or "Disabled")..[[ 
Load?]],
        {
          "Yes",
          "No"
        }
      )
      if button == "No" then
        tProgress = {
          dir = {}
        }
      end
    end
  else
    tProgress = {
      dir = {}
    }
  end
  if not (tProgress.layers) then
    local tSelection = {}
    for i=1,#tBlueprint do
      tSelection[i] = {
        text = tostring(i),
        selected = true
      }
    end
    local button, tRes, reinput = window.scroll(
      "Select layers to build",
      tSelection,
      true,
      true
    )
    while button ~= "Cancel" do
      if #tRes < 1 then
        button, tRes, reinput = reinput("Atleast 1 layer must be selected")
      else
        tProgress.layers = {}
        for i,v in ipairs(tRes) do
          tProgress.layers[i] = tonumber(v)
        end
        break
      end
    end
    if button == "Cancel" then
      return false
    end
  end
  local tUsage = checkUsage(blueprint,tProgress.layers)
  local fuelUsage = tUsage.fuel
  tUsage.fuel = nil
  for k,v in pairs(tUsage) do
    if not tBlueprint.colorSlots[k][1] then
      if not assignColorSlots(k) then
        window.text("Construction cancelled.")
        return false
      end
    end
  end
  blueprint:save(fileName or tFile.blueprint)
  if not tProgress.x then
    local button, tRes, reInput = window.text(
      "Input build coordinates",
      {
        "Cancel",
        "Ok",
        (cTurtle and "Cur pos" or nil)
      },
      {
        {
          name = "X",
          value = cTurtle and cTurtle.tPos.x or "",
          accepted = "[+%d-]"
        },
        {
          name = "Y",
          value = cTurtle and cTurtle.tPos.y or "",
          accepted = "[%d+-]"
        },
        {
          name = "Z",
          value = cTurtle and cTurtle.tPos.z or "",
          accepted = "[%d+-]"
        },
      },
      false,
      true
    )
    while true do
      if button == "Cancel" then
        window.text("Construction cancelled.")
        return
      elseif button == "Cur pos" then
        tRes.X = cTurtle.tPos.x
        tRes.Y = cTurtle.tPos.y
        tRes.Z = cTurtle.tPos.z
      end
      if not tRes.X then
        button,tRes,reInput = reinput("Missing parameter X!")
      elseif not tRes.Y then
        button,tRes,reInput = reinput("Missing parameter Y!")
      elseif not tRes.Z then
        button,tRes,reInput = reinput("Missing parameter Z!")
      elseif button == "Ok" or button == "Cur pos" then
        tProgress.x = tRes.X
        tProgress.y = tRes.Y
        tProgress.z = tRes.Z
        break
      end
    end
  end
  if not tProgress.dir.x then
    local button, tRes, reInput = window.text(
      "Input build directions",
      {
        "Cancel",
        "Ok",
      },
      {
        {
          name = "X",
          value = "+",
          accepted = "[+-]",
          charLimit = 1
        },
        {
          name = "Y",
          value = "+",
          accepted = "[+-]",
          charLimit = 1
        },
        {
          name = "Z",
          value = "+",
          accepted = "[+-]",
          charLimit = 1
        },
      },
      false,
      true
    )
    while true do
      if button == "Cancel" then
        window.text("Construction cancelled.")
        return
      elseif not tRes.X then
        button,tRes,reInput = reinput("Missing X direction!")
      elseif not tRes.Y then
        button,tRes,reInput = reinput("Missing Y direction!")
      elseif not tRes.Z then
        button,tRes,reInput = reinput("Missing Z direction!")
      elseif button == "Ok" then
        tProgress.dir.x = tRes.X
        tProgress.dir.y = tRes.Y
        tProgress.dir.z = tRes.Z
        break
      end
    end
  end
  if not tProgress.enderChest and not auto then
    local button, tRes, reInput = window.text(
      "Enable ender chest?",
      {
        "No",
        "Ok",
        (cTurtle and "Permanent" or nil)
      },
      {
        {
          name = "Slot",
          value = "",
          accepted = "%d",
          charLimit = 2
        },
      },
      false,
      true
    )
    while button ~= "No" do
      if not tRes.Slot then
        break
      elseif tRes.Slot and (tRes.Slot > 16 or tRes.Slot < 1 ) then
        button,tRes,reInput = reinput("Invalid slot "..tRes.Slot)
      elseif button == "Ok" then
        tProgress.enderChest = tRes.Slot
        if cTurtle then
          cTurtle.tSettings.enderFuel = tRes.Slot
        end
        break
      elseif button == "Permanent" then
        tProgress.enderChest = tRes.Slot
        cTurtle.tSettings.enderFuel = tProgress.enderChest
        cTurtle.saveSettings()
        break
      end
    end
  end
  if not tProgress.breakMode and not auto then
    local button = window.text(
      "Enable break mode?",
      {
        "No",
        "Yes"
      }
    )
    tProgress.breakMode = (button == "Ok" or button == "Yes")
  end
  saveProgress(fileName,tProgress)
  return tProgress,fileName
end

function build(blueprint,auto)
  --builds the given blueprint layers
  if not tFile.blueprint then
    if not dialogue.save"Blueprint must be saved locally prior to building" then
      window.text"Construction cancelled"
      return
    end
  end
  blueprint = blueprint or tBlueprint
  local tOngoing 
  if not auto then
    tOngoing = checkProgress(tFile.blueprint)
    if not tOngoing then
      window.text"Construction cancelled"
      return
    end
    local button = window.text(
      "Enable auto resume?",
      {
        "No",
        "Yes"
      }
    )
    if button == "Yes" or button == "Ok" then
      local file = class.fileTable.new("/startup")
      if not file:find([[shell\.run("]]..tFile.program.." .- -r") then
        file:write(
[[--Turtle Architect auto recovery
if fs.exists("]]..tFile.blueprint..[[.TAo") then
  shell.run("]]..tFile.program.." "..tFile.blueprint..[[ -r")
end]]
        )
        file:save()
      end
    end
  else
    tOngoing = loadProgress(tFile.blueprint)
  end
  cTurtle.tSettings.enderFuel = tOngoing.enderChest
  screen:refresh()
  local digSlot = blueprint.colorSlots.X[1] or 1
  tOngoing.dropoff = #blueprint.colorSlots.X > 1 and tOngoing.enderChest and blueprint.colorSlots.X[#blueprint.colorSlots.X]
  local dirX = tOngoing.dir.x
  local dirZ = tOngoing.dir.z
  local dirY = tOngoing.dir.y
  local buildDir = dirY == "+" and "Y-" or "Y+"
  local revBuildDir = dirY == "+" and "Y+" or "Y-"
  local blockAbove
  local saveCount = 0
  local function moveTo(nL,nX,nZ,skipCheck)
    local mL = tonumber(dirY..nL-1)
    local mX = tonumber(dirX..nX-1)
    local mZ = tonumber(dirZ..nZ-1)
    local cL = math.abs(cTurtle.tPos.y)-math.abs(tOngoing.y)+1
    local cX = math.abs(cTurtle.tPos.x)-math.abs(tOngoing.x)+1
    local cZ = math.abs(cTurtle.tPos.z)-math.abs(tOngoing.z)+1
    local dL = tonumber(nL..dirY..(1))
    cTurtle.moveTo(tOngoing.y + mL,"Y",tOngoing.breakMode and digSlot)
    if blueprint[dL] then
      for iL=math.min(cL,dL),math.max(nL,dL) do
        local xLine = blueprint[iL][cX]
        if xLine[cZ] == "X" then
          xLine[cZ] = nil
          sync(
            {
              layer = iL,
              x = cX,
              z = cZ,
              isBuilding = true
            },
            "Point"
          )
        end
      end
      local layer = blueprint[dL]
      cTurtle.moveTo(tOngoing.x + mX,"X",tOngoing.breakMode and digSlot)
      for iX=math.min(cX,nX),math.max(nX,cX) do
        local xLine = layer[iX]
        if xLine[cZ] == "X" then
          xLine[cZ] = nil
          sync(
            {
              layer = dL+1,
              x = iX,
              z = cZ,
              isBuilding = true
            },
            "Point"
          )
        end
      end
      local xLine = layer[nX]
      cTurtle.moveTo(tOngoing.z + mZ,"Z",tOngoing.breakMode and digSlot)
      for iZ=math.min(cZ,nZ),math.max(nZ,cZ) do
        if xLine[iZ] == "X" then
          xLine[iZ] = nil
          sync(
            {
              layer = dL+1,
              x = nX,
              z = iZ,
              isBuilding = true
            },
            "Point"
          )
        end
      end
    else
      cTurtle.moveTo(tOngoing.x + mX,"X",tOngoing.breakMode and digSlot)
      cTurtle.moveTo(tOngoing.z + mZ,"Z",tOngoing.breakMode and digSlot)
    end
  end
  for iL,nL in ipairs(tOngoing.layers) do
    local layerCopy = blueprint[nL]:copy() --table copy because fuck you next
    for nX,vX in pairs(layerCopy) do
      for nZ in pairs(vX) do
        local block = blueprint[nL][nX][nZ]
        local nX = nX
        while block do
          if block:match"%l" then --unbuilt block
            moveTo(nL,nX,nZ)
            if not selectColor(block,2) then
              window.text("Construction cancelled.")
              return
            end
            cTurtle.replace(buildDir,false,digSlot)
            blueprint[nL][nX][nZ] = block:upper()
            saveCount = saveCount+1
            if saveCount >= 25 then
              blueprint:save(tFile.blueprint,true)
              saveCount = 0
            end
            sync(
              {
                layer = nL,
                x = nX,
                z = nZ,
                color = block:upper(),
								isBuilding = true
              },
              "Point"
            )
            scroll(nL,nX-math.floor(tTerm.canvas.tX/2),nZ-math.floor(tTerm.canvas.tZ/2),true,true)
            screen:refresh()
          elseif block == "X" then --break block
            if not blockAbove then
              moveTo(nL,nX,nZ)
            end
            turtle.select(blueprint.colorSlots.X[1])
            if tOngoing.dropoff then
              if turtle.getItemCount(tOngoing.dropoff) > 0 then
                cTurtle.enderDropoff(cTurtle.tSettings.enderFuel,tBlueprint.colorSlots.X,tBlueprint.colorSlots.X)
              end
            elseif turtle.getItemCount(blueprint.colorSlots.X[#blueprint.colorSlots.X]) > 0 then
              cTurtle.drop("Y-",false,64)
            end
            cTurtle.dig(blockAbove and revBuildDir or buildDir)
            blueprint[nL][nX][nZ] = nil
            saveCount = saveCount+1
            if saveCount >= 25 then
              blueprint:save(tFile.blueprint,true)
              saveCount = 0
            end
            sync(
              {
                layer = nL,
                x = nX,
                z = nZ,
								isBuilding = true
              },
              "Point"
            )
            scroll(nL,nX-math.floor(tTerm.canvas.tX/2),nZ-math.floor(tTerm.canvas.tZ/2),true,true)
            screen:refresh()
          elseif block == "S" then --scan block
            if not blockAbove then
              moveTo(nL,nX,nZ)
            end
            if cTurtle.detect(blockAbove and revBuildDir or buildDir) then
              local identified
              for i,slot in ipairs(blueprint.colorSlots.S[1]) do
                if cTurtle.compare(buildDir,slot) then
                  identified = i
                  break
                end
              end
              identified = identified and blueprint.colorSlots.S.color[identified] or blueprint.colorsSlots.S.color.unidentified
              blueprint[nL][nX][nZ] = identified
              if saveCount >= 25 then
                blueprint:save(tFile.blueprint,true)
                saveCount = 0
              end
              sync(
                {
                  layer = nL,
                  x = nX,
                  z = nZ,
                  color = identified,
                  isBuilding = true
                },
                "Point"
              )
              scroll(nL,nX-math.floor(tTerm.canvas.tX/2),nZ-math.floor(tTerm.canvas.tZ/2),true,true)
              screen:refresh()
            else
              blueprint[nL][nX][nZ] = nil
              saveCount = saveCount+1
              if saveCount >= 25 then
                blueprint:save(tFile.blueprint,true)
                saveCount = 0
              end
              sync(
                {
                  layer = nL,
                  x = nX,
                  z = nZ,
                  isBuilding = true
                },
                "Point"
              )
              scroll(nL,nX-math.floor(tTerm.canvas.tX/2),nZ-math.floor(tTerm.canvas.tZ/2),true,true)
              screen:refresh()
            end
          end
          if blockAbove and (blockAbove == "X" or blockAbove == "S") then
            nL = dirY == "+" and nL-2 or nL+2
            blockAbove = false
          else
            blockAbove = ( --check for block above/below turtle
              dirY == "+" and (rawget(blueprint,nL+2) and blueprint[nL+2][nX][nZ]) 
              or (rawget(blueprint,nL-2) and blueprint[nL-2][nX][nZ])
            )
          end
          if blockAbove and (blockAbove == "X" or blockAbove == "S") then
            block = blockAbove
            nL = dirY == "+" and nL+2 or nL-2
          else
            block = nil
            local nextBlock = {}
            local dir = cTurtle.tPos.dir
            local iX1 = 1
            local iX2 = -1
            local iX3 = -1
            local iZ1 = 1
            local iZ2 = -1
            local iZ3 = -1
            if dir == 3 then
              iX1 = -1
              iX2 = 1
              iX3 = 1
            elseif dir == 4 then
              iZ1 = -1
              iZ2 = 1
              iZ3 = 1
            end
            for iX=iX1,iX2,iX3 do --scan for blocks in vicinity
              for iZ=iZ1,iZ2,iZ3 do
                local newBlock = blueprint[nL][nX+iX][nZ+iZ]
                if newBlock and newBlock:match"[XS%l]" then
                  nextBlock = {
                    b = newBlock,
                    nX = nX+iX,
                    nZ = nZ+iZ
                  }
                  if iZ == 0
                  or iX == 0 then --1 block away, diagonal blocks are second priority
                    block = nextBlock.b
                    nextBlock.nonDiagonal = true
                    break
                  end
                end
              end
              if  nextBlock.nonDiagonal then
                break
              end
            end
            block = block or nextBlock.b
            nX = nextBlock.nX
            nZ = nextBlock.nZ
          end
        end
      end
    end
		if tMode.sync.amount > 0 then
			rednet.send(tMode.sync.ids,"Turtle status",{type = "Layer complete", blueprintName = tFile.blueprint, layer = nL})
    end
  end
  blueprint:save(tFile.blueprint,true)
	if tMode.sync.amount > 0 then
	  rednet.send(tMode.sync.ids,"Turtle status",{type = "Build complete", blueprintName = tFile.blueprint})
	end
  if auto then
    local file = class.fileTable.new("/startup")
    local line = file:find("--Turtle Architect auto recovery")
    if line then
      for i=line+3,line,-1 do
        file:delete(i)
      end
    end
    file:save()
  end
end