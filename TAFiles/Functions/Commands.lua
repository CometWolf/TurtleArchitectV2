function saveProgress(fileName,tProgress)
  local file = class.fileTable.new()
  file:write("layers: "..textutils.serialize(tProgress.layers):gsub("\n%s-",""))
  file:write("X: "..tProgress.x)
  file:write("Y: "..tProgress.y)
  file:write("Z: "..tProgress.z)
  file:write("dir X: "..tProgress.dir.x)
  file:write("dir Y: "..tProgress.dir.y)
  file:write("dir Z: "..tProgress.dir.z)
  file:write("Enderchest: Disabled")
  file:write("Break mode: Disabled")
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
  file.close()
  return tOngoing
end

function assignColorSlots(color)
  local button, tRes, reInput = window.text(
    "Input block ID for "..keyColor[color],
    {
      "Cancel",
      "Ok",
    },
    {
      {
        name = "ID",
        accepted = "[%d:]",
      },
    },
    false,
    true
  )
  while button ~= "Cancel" do
    if not tRes.ID then
      button, tRes, reInput = reInput"Missing block ID parameter!"
    else
      tBlueprint.colorSlots[color] = tRes.ID
      return true
    end
  end
  return false
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
  local tUsage = {}
  local loop = 0
  for iL,nL in ipairs(tLayers) do
    for nX,vX in pairs(blueprint[nL]) do
      for nZ,block in pairs(vX) do
        local nX = nX
        if block:match"[%lX]" then
          tUsage[block] = (tUsage[block] or 0)+1
        end
      end
    end
    loop = loop+1
    if loop%100 == 0 then
      sleep(0.05)
    end
  end
  return tUsage
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
    if not tBlueprint.colorSlots[k] or type(tBlueprint.colorSlots[k]) ~= "number" then
      if not assignColorSlots(k) then
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
        ((cTurtle or commands) and "Cur pos" or nil)
      },
      {
        {
          name = "X",
          value = cTurtle and cTurtle.tPos.x or commands and tPos.x or "",
          accepted = "[+%d-]"
        },
        {
          name = "Y",
          value = cTurtle and cTurtle.tPos.y or commands and tPos.y or "",
          accepted = "[%d+-]"
        },
        {
          name = "Z",
          value = cTurtle and cTurtle.tPos.z or commands and tPos.z or "",
          accepted = "[%d+-]"
        },
      },
      false,
      true
    )
    while true do
      if button == "Cancel" then
        return false
      elseif button == "Cur pos" then
        if cTurtle then
          tRes.X = cTurtle.tPos.x
          tRes.Y = cTurtle.tPos.y
          tRes.Z = cTurtle.tPos.z
        else
          tRes.X = tPos.x
          tRes.Y = tPos.y+1
          tRes.Z = tPos.z
        end
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
        return false
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
  saveProgress(fileName,tProgress)
  return tProgress,fileName
end

function build(blueprint)
  --builds the given blueprint layers
  if not tFile.blueprint then
    if not dialogue.save"Blueprint must be saved locally prior to building" then
      window.text"Construction cancelled"
      return
    end
  end
  blueprint = blueprint or tBlueprint
  local tOngoing 
  tOngoing = checkProgress(tFile.blueprint)
  if not tOngoing then
    window.text"Construction cancelled."
    return
  else
    tOngoing = loadProgress(tFile.blueprint)
  end
  screen:refresh()
  local dirX = tOngoing.dir.x
  local dirZ = tOngoing.dir.z
  local dirY = tOngoing.dir.y
  local loop = 0
  for iL,nL in ipairs(tOngoing.layers) do
    local layerCopy = blueprint[nL]:copy() --table copy because fuck you next
    for nX,vX in pairs(layerCopy) do
      for nZ in pairs(vX) do
        local block = blueprint[nL][nX][nZ]
        if block and block:match"[%lX]" then
          if block == "X" then
            commands.execAsync("setblock "..tOngoing.x + tonumber(dirX..nX-1).." "..tOngoing.y + tonumber(dirY..nL-1).." "..tOngoing.z + tonumber(dirZ..nZ-1).." 0")
            blueprint[nL][nX][nZ] = nil
          else
            commands.execAsync("setblock "..tOngoing.x + tonumber(dirX..nX-1).." "..tOngoing.y + tonumber(dirY..nL-1).." "..tOngoing.z + tonumber(dirZ..nZ-1).." "..tBlueprint.colorSlots[block])
            blueprint[nL][nX][nZ] = block:upper()
          end
          loop = loop+1
          if loop%10000 == 0 then
            blueprint:save(tFile.blueprint,true)
            scroll(nL,nX-math.floor(tTerm.canvas.tX/2),nZ-math.floor(tTerm.canvas.tZ/2),true,true)
            screen:refresh()
            sleep(1)
          end
        end
      end
    end
  end
  blueprint:save(tFile.blueprint,true)
  scroll()
  window.text"Construction complete"
end