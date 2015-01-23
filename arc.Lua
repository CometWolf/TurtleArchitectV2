--[[
--------------------------------------------------------------------------------------------------------------
|                                              Turtle Architect                                              |
|                                                by CometWolf                                                |
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
environment init
----------------------------------------------------------------------------------------------------------]]--
local env = {  --new environment
  tFile = {
  --file path table, edit in the File paths section
    ["program"] = shell.getRunningProgram(), --must be done prior to changing environment
  }
}

env.progEnv = setmetatable(env, {__index = getfenv()}) --inherit global
setfenv(1, env)    --set it, now all variables are local to this script.
tArg = {...} --store program arguments

--[[----------------------------------------------------------------------------------------------------------
File paths
----------------------------------------------------------------------------------------------------------]]--
tFile.folder = (tFile.program:match"^(.+/).-$" or "").."/TAFiles" --program files folder
tFile.classFolder = tFile.folder.."/Classes" --classes folder
tFile.menuFolder = tFile.folder.."/Menus" --menu tables folder
tFile.mainMenuFolder = tFile.menuFolder.."/mainMenus" --main menus folder
tFile.toolFolder = tFile.folder.."/Tools" --tools folder
tFile.eventHandlerFolder = tFile.folder.."/EventHandlers"
tFile.cTurtle = "/cTurtle" --cTurtle API,downloaded automatically if missing on a turtle.
tFile.settings = tFile.folder.."/Settings.Lua" --settings file
tFile.installer = tFile.folder.."/installer.Lua" --github installer, used for updates

tPaste = {
--pastebin codes and functions
  program = "VTZ6CqWY", --program installer
  cTurtle = "JRPN0P8x", --Turtle API, downloaded automatically if needed
  key = "0ec2eb25b6166c0c27a394ae118ad829", -- pastbin dev key, cc default
}

--[[----------------------------------------------------------------------------------------------------------
local API mods
----------------------------------------------------------------------------------------------------------]]--

os = setmetatable(
  {
    sleepTimer = {},
    sleep = function(time)
      local sleeping = true
      os.sleepTimer[os.startTimer(time)] = function()
        sleeping = false
      end
      while sleeping do
        eventHandler.pull()
      end
    end,
    id = _G.os.getComputerID()
  },
  {
    __index = _G.os
  }
)

math = setmetatable(
  {
    round = function(num)
      return math.floor(num+0.5)
    end
  },
  {
    __index = _G.math
  }
)

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

http = setmetatable(
  {
    paste = {
      get = function(code,file)
        local paste
        local response = http.get("http://pastebin.com/raw.php?i="..code)
        if response then
        --sucesss
          if file == true then
            --save to table
            local tLines = {}
            local line = response.readLine()
            while line do
              tLines[#tLines+1] = line
              line = response.readLine()
            end
            return tLines
          elseif file then
            --save to file
            local paste = response.readAll()
            response.close()
            local file = fs.open(file,"w")
            file.write(paste)
            file.close()
            return true
          else
            --save to variable
            local paste = response.readAll()
            response.close()
            return paste
          end
        else
          --failure
          return false
        end
      end,
      put = function(file,name)
        local upload
        if type(file) == "string" and fs.exists(file) then
        --local file
          file = fs.open("file","r")
          upload = file.readAll()
          file.close()
        elseif type(file) == "table" then
        --blueprint
          upload = file:save(true)
        end
        local key = tPaste.key
        local response = http.post(
          "http://pastebin.com/api/api_post.php",
          "api_option=paste&"..
          "api_dev_key="..key.."&"..
          "api_paste_format=text&"..
          "api_paste_name="..textutils.urlEncode(name or "Untitled").."&"..
          "api_paste_code="..textutils.urlEncode(upload)
        )
        if response then
        --sucess
          local sResponse = response.readAll()
          response.close()      
          local sCode = string.match( sResponse, "[^/]+$" )
          return sResponse, sCode
        else
          --failure
          return false
        end
      end
    }
  },
  {
    __index = _G.http
  }
)

rednet = {
  send = function(rID,event,content,success,timeout,time,failure)
    content = content or {}
    content.rID = type(rID) == "table" and rID or {[rID] = true}
    content.sID = os.id
    content.event = event
    local clear
    for id in pairs(content.rID) do
      local timerId
      if timeout then
        timerId = tTimers.modemRes.start(time) --if not time, the default modemRes time is used
        clear = function(rID,tID)
          tTimers.modemRes.ids[tID] = nil
          tTransmissions.failure.timeout[tID] = nil
          tTransmissions.failure[event][rID] = nil
          tTransmissions.success[event][rID] = nil
        end
        tTransmissions.failure.timeout[timerId] = function()
          clear(id,timerId)
          timeout(id)
        end
      end
      clear = clear or function(rID) --different clear if there is no timeout function
        tTransmissions.failure[event][rID] = nil
        tTransmissions.success[event][rID] = nil
      end
      tTransmissions.success[event][id] = (
        success 
        and function(data)
          clear(id,timerId)
          success(id,data)
        end
        or function() 
          clear(id,timerId)
        end
      )
      tTransmissions.failure[event][rID] = (
        failure
        and function()
          clear(id,timerId)
          failure(id)
        end
        or clear
      )
    end
    modem.transmit(
      modemChannel,
      modemChannel,
      content
    )
  end,
  connected = { --connected computers
    amount = 0,
    ids = {
      
    }
  },
  connect = function(id,type,time,success)
    rednet.send(
      id,
      "Init connection",
      {
        type = type,
        turtle = turtle and true
      },
      function(id,data)
        rednet.connected.ids[id] = true
        rednet.connected.amount = rednet.connected.amount+1
        --tTimers.connectionPing.start()
        if success then
          success(id,data)
        end
      end,
      function(id)
        window.text("Failed to connect to computer ID "..id..".")
      end,
      time,
      function(id)
        window.text("Computer ID "..id.." denied your connection request")
      end
    )
  end,
  disconnect = function(ids)
    ids = type(ids) == "table" and ids or {[ids] = true}
    rednet.send(ids,"Close connection")
    local idsLoop = {}
    for id in pairs(ids) do
      idsLoop[#idsLoop+1] = id
    end
    for i = 1,#idsLoop do
      local id = idsLoop[i]
      rednet.connected.ids[id] = nil
      rednet.connected.amount = rednet.connected.amount-1
      if tMode.sync.ids[id] then
        tMode.sync.turtles = tMode.sync.ids[id] == "turtle" and tMode.sync.turtles-1 or tMode.sync.turtles
        tMode.sync.ids[id] = nil
        tMode.sync.amount = tMode.sync.amount-1
      end
    end
  end
}
setmetatable(
  rednet,
  {
  __index = _G.rednet
  }
)
--[[----------------------------------------------------------------------------------------------------------
Debug functions
----------------------------------------------------------------------------------------------------------]]--
debug = {
  times = 0,
  tExecutionTime = {
    program = os.clock()
  },
  tEventQueue = {},
  prep = function()
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.white)
  end,
  pause = function()
    local tEventQueue = {}
    while true do
      local tEvent = {os.pullEventRaw()}
      if tEvent[1] == "key" then
        if tEvent[2] == 14 then
          error("Quit",0)
        else
          return
        end
      elseif tEvent[1] == "mouse_click"
      or tEvent[1] == "mouse_drag"
      or tEvent[1] == "mouse_scroll" then
        --ignore user input
      else
        debug.tEventQueue[#debug.tEventQueue+1] = tEvent
      end
    end
  end,
  variables = function(...)
    debug.times = debug.times+1
    local tLines = {}
    for i=1,#arg do
      local var = arg[i]
      if not var then
        tLines[#tLines+1] = "nil"
      elseif type(var) == "table" then
        for k,v in pairs(var) do
          tLines[#tLines+1] = k..": "..type(v).." "..tostring(v)
        end
      else
        tLines[#tLines+1] = type(var).." "..tostring(var)
      end
    end
    local lines = tTerm.screen.y-3
    local pages = math.ceil(#tLines/lines)
    for page = 1,pages do
      debug.prep()
      print("Page "..page.."/"..pages.." Debug call #"..debug.times.." on "..tFile.program)
      for line = lines*(page-1)+1,lines*page do
        if not tLines[line] then
          break
        else
          print(tLines[line])
        end
      end
      debug.pause()
    end
    if screen then
      screen:redraw()
    end
    for _i,event in ipairs(debug.tEventQueue) do
      os.queueEvent(unpack(event))
    end
    debug.tEventQueue = {}
    return
  end,
  timedStart = function(key)
    debug.tExecutionTime[k] = os.clock()
  end,
  timedEnd = function(key)
    local endTime = os.clock()
    debug.prep()
    assert(debug.tExecutionTime[key],"Attempt to check non-defined execution time "..key)
    print("Initiated at "..debug.tExecutionTime[key])
    print("Completed at "..endTime)
    print("Total run time: "..endTime-debug.tExecutionTime[key])
    debug.pause()
  end
}
setmetatable(debug,
  {
    __call = function(t,...)
      return debug.variables(...)
    end
  }
)

--[[----------------------------------------------------------------------------------------------------------
Load class files
----------------------------------------------------------------------------------------------------------]]--
function loadFile(path,env,arg) --custom file loader, sets environment, handles errors and runs file and returns results
  if not path then
    return
  end
  assert(fs.exists(path),"Error: Attempted to load non-existent file "..path.."!")
  local tRes = {loadfile(path)}
  if not tRes[1] then
    error("The following error occured while loading "..path..": "..tRes[2],2)
  end
  local func = setfenv(tRes[1],progEnv)
  tRes = {
    pcall(
      function()
        return func(arg)
      end
    )
  }
  if not tRes[1] then
    error("The following error occured while loading "..path..":\n"..tRes[2],2)
  end
  return unpack(tRes,2)
end

--load class files
class = {}
for _k,file in pairs(fs.list(tFile.classFolder)) do
  class[file:match"(.+)%.Lua"] = loadFile(tFile.classFolder.."/"..file,progEnv)
end

--[[----------------------------------------------------------------------------------------------------------
Assorted variables
----------------------------------------------------------------------------------------------------------]]--
tTerm = { --screen size and canvas area
  screen = {}, --screen size
  canvas = {}, --canvas size
  scroll = {}, --canvas scroll amount
  viewable = {} --currently visible canvas area
}
tTerm.screen.x,tTerm.screen.y = term.getSize()
tTerm.screen.xMid = math.floor(tTerm.screen.x/2) --middle of the screen sideways
tTerm.screen.yMid = math.floor(tTerm.screen.y/2) --middle of the screen up and down
tTerm.canvas.sX = 1 --canvas left side
tTerm.canvas.eX = tTerm.screen.x-2 --canvas edge
tTerm.canvas.tX = tTerm.canvas.eX-tTerm.canvas.sX+1 --canvas total length
tTerm.canvas.sZ = 1 --canvas top side
tTerm.canvas.eZ = tTerm.screen.y-1 --canvas bottom
tTerm.canvas.tZ = tTerm.canvas.eZ-tTerm.canvas.sZ+1 --canvas total height
tTerm.viewable.sX = 1 --left side of the blueprint in view
tTerm.viewable.eX = tTerm.canvas.eX --edge of the blueprint in view
tTerm.viewable.sZ = 1 --top side of the blueprint in view
tTerm.viewable.eZ = tTerm.canvas.eZ --bottom of the blueprint in view
tTerm.viewable.mX = 0 --view modifier sideways
tTerm.viewable.mZ = 0 --view modifier up or down
tTerm.scroll.x = 0 --canvas scroll sideways
tTerm.scroll.z = 0 --canvas scroll up or down
tTerm.scroll.layer = 1 --currently in view layer
tTerm.color = term.isColor()

tOngoing = { --stores ongoing build info
  dir = {}, --stores build directions
  breakMode = false --whether turtle will break obstructions automatically.
}

screen = class.screenBuffer.new() --screen buffer, supports layers and uses custom methods, no silly redirect here.
screen.layers = { --screen layers
  canvas = 1,
  toolsOverlay = 2,
  bottomBar = 3,
  sideBar = 3,
  gridBorder = 3,
  layerBar = 3,
  menus = 4,
  dialogue = 5
}

tBar = { --menu bar variables
  menu = {
    touchMap = class.matrix.new(2) --used for open menus
  },
  layerBar = {
    --open = tMode.layerBar, change this in the settings menu. true by default
    sX = tTerm.canvas.eX,
    eX = tTerm.canvas.eX,
    sZ = 1,
    eZ = tTerm.canvas.eZ,
    sL = 1,
    eL = tTerm.canvas.eZ,
    tSelected = {
      [1] = true
    },
    selectedAmt = 1,
    prevSelected = 1,
    clipboard = false,
  },
  touchMap = class.matrix.new(2) --used for clicks on the side and bottom bar
}

tTransmissions = { --stores reaction functions to modem transmissions
  success = class.matrix.new(2), --received a success response, stored by event type and sender id
  failure = class.matrix.new( --received a failure response, stored by event type and sender id
    2,
    {
      timeout = {} --timed out, stored by timer id
    }
  )
}

tIgnore = { --ids of turtles to ignore status messages from

}
--load settings
loadFile(tFile.settings)

--[[----------------------------------------------------------------------------------------------------------
Glass functions
----------------------------------------------------------------------------------------------------------]]--
--the screen functions are part of the buffer class
glasses.log.open = function(sX,sY,eX,eY)
  glasses.lines = {
    background = glasses.bridge.addBox(sX,eY-1,eX-sX,1,tColors.glass.log,glasses.log.opacity)
  }
  glasses.lines.background.setZ(1)
  for i = eY-10,sY,-10 do
    glasses.lines[#glasses.lines+1] = glasses.bridge.addText(sX+1,i+1," ",tColors.glass.logText)
    local line = glasses.lines[#glasses.lines]
    line.setZ(2)
    line.setAlpha(glasses.log.opacity)
	end
  local file = class.fileTable.new(tFile.settings)
  local line = file:find("  log = { --where to render the message bar",true)
  file:write(
[[    sX = ]]..sX..[[,
    sY = ]]..sY..[[,
    eX = ]]..eX..[[,
    eY = ]]..eY..[[,]],
    line+1
  )
  file:save()
	glasses.lineLength = math.floor((eX-sX)/5)
  glasses.log.refresh()
end

glasses.log.write = function(text,time)
  local timerId = tTimers.display.start()
  local logLine = {text = text,visible = true}
  table.insert(glasses.log,1,logLine)
  glasses.log.timers[tTimers.display.start(time)] = function()
    logLine.visible = false
  end
  glasses.log[glasses.log.maxSize+1] = nil
  if glasses.screenMode:match"Log" then
    glasses.log.refresh()
  end
end

glasses.log.refresh = function()
  local curLine = 1
	local curLog = 1
  while #glasses.lines >= curLine do
    while glasses.log[curLog] and not glasses.log[curLog].visible do
      curLog = curLog+1
    end
    if not glasses.log[curLog] then
      break
    end
	  local text = glasses.log[curLog].text
    if not text then 
      break
    end
    local tLines = string.lineFormat(text,glasses.lineLength)
    for i=#tLines,1,-1 do
      glasses.lines[curLine].setText(tLines[i])
      curLine = curLine+1
      if not glasses.lines[curLine] then
        break
      end
    end
    curLog = curLog+1
  end
  for i=curLine,#glasses.lines do
    glasses.lines[i].setText""
  end
  local background = glasses.lines.background
  local upper = glasses.log.eY-(10*(curLine-1))
  background.setY(upper)
  background.setHeight(glasses.log.eY-upper)
end

glasses.log.setOpacity = function(opacity)
  glasses.lines.background.setOpacity(opacity)
  for i=1,#glasses.lines do
    glasses.lines[i].setAlpha(opacity)
  end
  local file = class.fileTable.new(tFile.settings)
  local line = file:find("    opacity = %d%.?%d?%d?d?, %-%-log transparency")
  file:write("    opacity = "..opacity..", --log transparency",line)
  file:save()
end

glasses.log.close = function()
  glasses.log.lines.background.delete()
	for i=1,#glasses.log.lines do
    glasses.log.lines[i].delete()
	end
	glasses.log.lines = nil
end

--[[----------------------------------------------------------------------------------------------------------
Program init
----------------------------------------------------------------------------------------------------------]]--

if turtle then
  if not fs.exists(tFile.cTurtle) then
    assert(http.paste.get(tPaste.cTurtle,tFile.cTurtle),"Error: Failed to download cTurtle API")
  end
  os.loadAPI(tFile.cTurtle)
  cTurtle.tSettings.renderMove = false
  if modem then --cTurtle handles modem wrapping on turtles
    modem.open(modemChannel)
  end
  cTurtle.eventHandler["modem_message"] = rednet.received
elseif term.isColor() then
  for k,side in pairs(peripheral.getNames()) do
    local pType = peripheral.getType(side)
    if pType == "modem"
    and not modem
    and peripheral.call(side,"isWireless") then
      modem = peripheral.wrap(side)
      modem.side = side
      modem.open(modemChannel)
    elseif pType == "openperipheral_glassesbridge"
    and not glasses.bridge then
      glasses.bridge = peripheral.wrap(side)
      glasses.side = side
      glasses.bridge.clear()
      if glasses.screenMode:match"Screen" then
        screen:glassInit(glasses.bridge,glasses.screen.size.x,glasses.screen.size.y,glasses.screen.pos.x,glasses.screen.pos.y)
      end
      if glasses.screenMode:match"Log" then
			  glasses.log.open(glasses.log.sX,glasses.log.sY,glasses.log.eX,glasses.log.eY)
        glasses.log.write("Welcome to Turtle Architect V2",5)
      end
    end
    if glasses.bridge and modem then
      break
    end
  end
else
  error("Turtle Architect is incompatible with regular computers!",0)
end
if not glasses.bridge then
  glasses.screenMode = ""
end

if tArg[1] then --attempt to load argument blueprint
  tBlueprint = class.blueprint.load(tArg[1]) or class.blueprint.new()
  tFile.blueprint = tArg[1]
else
  tBlueprint = class.blueprint.new()
end

--load menus
--tools are loaded within the Tools menu file
tMenu = {}
for _k,file in pairs(fs.list(tFile.menuFolder)) do
  if not fs.isDir(tFile.menuFolder.."/"..file) then
    tMenu[file:match"(.+)%.Lua"] = loadFile(tFile.menuFolder.."/"..file,progEnv)
  end
end

--[[----------------------------------------------------------------------------------------------------------
Sync functions
----------------------------------------------------------------------------------------------------------]]--

function sync(object,type)
  if tMode.sync.amount > 0 then 
    object.type = type
    rednet.send(
      tMode.sync.ids,
      "Sync edit",
      object
    )
  end
end

--[[----------------------------------------------------------------------------------------------------------
Rendering functions
----------------------------------------------------------------------------------------------------------]]--
function toggleMenus(FORCE) --Hides/reveals menus, FORCE reveal.
  local cX,cZ = 2,1 --cavnas size change
  if tMode.hideMenus or FORCE then --reveal
    tMode.hideMenus = false
    renderSideBar()
    renderBottomBar()
    if tMode.layerBar then
      openLayerBar()
    end
    local change = tMode.layer
    tTerm.canvas.eX = tTerm.canvas.eX-cX
    tTerm.canvas.tX = tTerm.canvas.eX-tTerm.canvas.sX+1
    tTerm.canvas.eZ = tTerm.canvas.eZ-cZ
    tTerm.canvas.tZ = tTerm.canvas.eZ-tTerm.canvas.sZ+1
    tTerm.viewable.eX = tTerm.viewable.eX-cX
    tTerm.viewable.eZ = tTerm.viewable.eZ-cZ
    if tMode.grid then
      renderGrid()
    end
  else --hide
    if tMode.layerBar then
      cX = cX+1
    end
    screen:clearLayer(screen.layers.bottomBar or screen.layers.sideBar or screen.layers.layerBar) --they all use the same layer
    if tMode.grid then --the grid border is on the same layer as the menus, and must be re-rendered
      removeGrid()
    end
    tBar.touchMap = class.matrix.new(2)
    tTerm.canvas.eX = tTerm.canvas.eX+cX
    tTerm.canvas.tX = tTerm.canvas.eX-tTerm.canvas.sX+1
    tTerm.canvas.eZ = tTerm.canvas.eZ+cZ
    tTerm.canvas.tZ = tTerm.canvas.eZ-tTerm.canvas.sZ+1
    tTerm.viewable.eX = tTerm.viewable.eX+cX
    tTerm.viewable.eZ = tTerm.viewable.eZ+cZ
    tMode.hideMenus = true
  end
  scroll()
end

function renderGrid() --renders grid overlay and borders
  local canvas = tTerm.canvas
  screen:setLayer(screen.layers.gridBorder)
  screen:setCursorPos(1,1)
  screen:setBackgroundColor(tColors.gridBorder)
  screen:setTextColor(tColors.gridBorderText)
  screen:write" "
  local nextChar = 1
  for i=2,canvas.eX do
    screen:write(string.format(nextChar))
    nextChar = nextChar+1
    nextChar = (nextChar < 10 and nextChar or 0)
  end
  screen:setCursorPos(1,2)
  nextChar = 1
  for i=2,canvas.eZ do
    screen:setCursorPos(1,i)
    screen:write(string.format(nextChar))
    nextChar = nextChar+1
    nextChar = (nextChar < 10 and nextChar or 0)
  end
  canvas.sX = canvas.sX+1
  canvas.tX = canvas.eX-canvas.sX
  canvas.sZ = canvas.sZ+1
  canvas.tZ = canvas.eZ-canvas.sZ
  local view = tTerm.viewable
  view.mX = view.mX+1
  view.mZ = view.mZ+1
  view.eX = view.sX+tTerm.canvas.tX
  view.eZ = view.sZ+tTerm.canvas.tZ
  scroll()
end

function removeGrid() --removes the grid border and overlay
  local canvas = tTerm.canvas
  canvas.sX = canvas.sX-1
  canvas.tX = canvas.eX-canvas.sX
  canvas.sZ = canvas.sZ-1
  canvas.tZ = canvas.eZ-canvas.sZ
  local view = tTerm.viewable
  view.mX = view.mX-1
  view.mZ = view.mZ-1
  view.eX = view.sX+tTerm.canvas.tX
  view.eZ = view.sZ+tTerm.canvas.tZ
  for i=1,canvas.eX do
    screen:delPoint(i,1,screen.layers.gridBorder)
  end
  for i=1,canvas.eZ do
    screen:delPoint(1,i,screen.layers.gridBorder)
  end
  scroll()
end

function renderBottomBar() --renders bottom bar and updates info
  if tMode.hideMenus then
    return
  end
  screen:setLayer(screen.layers.bottomBar)
  screen:setCursorPos(1,tTerm.screen.y)
  local bgColor = tColors.bottomBar
  screen:setBackgroundColor(bgColor)
  screen:setTextColor(tColors.toolText)
  local toolColor = colorKey[tTool[1].color]
  screen:write("T1: ")
  screen:setTextColor(toolColor)
  if toolColor == bgColor then
    screen:setBackgroundColor(tColors.toolText)
  end
  screen:write(tTool[1].tool)
  screen:setBackgroundColor(bgColor)
  screen:setTextColor(tColors.toolText)
  screen:write(" T2: ")
  toolColor = colorKey[tTool[2].color]
  screen:setTextColor(toolColor)
  if toolColor == bgColor then
    screen:setBackgroundColor(tColors.toolText)
  end
  screen:write(tTool[2].tool)
  screen:setTextColor(tColors.coordsText)
  screen:setBackgroundColor(bgColor)
  local cursX,cursY = screen:getCursorPos()
  local coordString = "X:"..tTerm.scroll.x.." Y:"..tTerm.scroll.layer.." Z:"..tTerm.scroll.z
  local screenX = tBar.menu.sizeReduction and tTerm.screen.x-4 or tTerm.screen.x-2
  screen:write(string.rep(" ",math.max(screenX-#coordString-cursX+1,0))..coordString)
  for iX = screenX-#coordString+1,screenX do
    tBar.touchMap[iX][cursY] = function(button)
      if tTool[button].tool == "Help" then
        window.text"These are the current view coordinates.\nX is left and right.\nZ is up and down.\nY is the current layer.\nClicking these without the help tool equipped will allow you to input them directly"
      else
        local button, tRes, reInput = window.text(
          "Go to",
          {
            "Ok",
            "Cancel"
          },
          {
            {
              name = "X",
              value = tTerm.scroll.x,
              accepted = "%d"
            },
            {
              name = "Y",
              value = tTerm.scroll.layer,
              accepted = "%d"
            },
            {
              name = "Z",
              value = tTerm.scroll.z,
              accepted = "%d"
            }
          },
          false,
          true
        )
        while button ~= "Cancel" do
          if not tBlueprint[tRes.Y] then
            button, tRes, reInput = reInput("The layer "..tRes.Y.." does not exist!\n The current top layer is "..#tBlueprint)
          else
            scroll(tRes.Y,tRes.X,tRes.Z,true)
            return
          end
        end
      end
    end
  end
end

function renderMenu(menu) --renders the given menu and activates the touch map for said menu
  tMenu.touchMap = class.matrix.new(2)
  screen:clearLayer(screen.layers.menus)
  if not menu 
  or not tMenu.main[menu] and not tMenu.rightClick[menu]
  or tMenu.main[menu] and (not tMenu.main[menu].enabled or type(tMenu.main[menu].enabled) == "function" and not tMenu.main[menu].enabled()) then
    tMenu.open = false
    return
  elseif tMenu.rightClick[menu] then
    tMenu.open = menu
    tMenu.rightClick.render(menu)
    return
  end
  tMenu.open = menu
  menu = tMenu.main[menu]
  screen:setLayer(screen.layers.menus)
  screen:setBackgroundColor(tColors.menuTop)
  screen:setTextColor(tColors.enabledMenuText)
  screen:setCursorPos(menu.sX,menu.sY)
  local extraSpaces = string.rep(" ",math.ceil((menu.eX-menu.sX-#menu.string)/2))
  local menuString = extraSpaces..menu.string..extraSpaces
  if #menuString > menu.lX*menu.splits then
    menuString = menuString:sub(2)
  end
  screen:write(menuString)
  for iX = menu.sX,menu.sX+#menuString do
    tMenu.touchMap[iX][menu.sY] = true --clicking the header does nothing, currently
  end
  local nextMenu = 0
  for split=1,menu.splits do
    local sX = menu.eX-(menu.lX*split)
    for i=1,math.ceil(#menu.items/menu.splits) do
      nextMenu = nextMenu+1
      if not menu.items[nextMenu] then
        break
      end
      local iMenu = nextMenu
      local sY = menu.sY+i
      local enabled = menu.items[iMenu].enabled
      if type(enabled) == "function" then
        enabled = enabled()
      end
      screen:setBackgroundColor(i%2 == 0 and tColors.menuPri or tColors.menuSec)
      screen:setTextColor(enabled and tColors.enabledMenuText or tColors.disabledMenuText)
      screen:setCursorPos(sX,sY)
      screen:write(menu.items[iMenu].string)
      local help = menu.items[iMenu].help
      local helpFunc = (
        help
        and function(button)
          return tTool[button].tool == "Help" and (help() or true)
        end
        or function(button)
          return tTool[button].tool == "Help" and window.text(menu.items[iMenu].name.."\ndosen't have a help function. Please define it in the menu file as \"help\"") and true
        end
      )
      local menuFunc = function(button)
        if not helpFunc(button) then
          renderMenu()
          menu.items[iMenu].func(button)
        end
      end
      for iX = sX,sX+menu.lX-1 do
        tMenu.touchMap[iX][sY] = enabled and menuFunc or helpFunc --true prevents the touchmap func from closing the menu
      end
    end
  end
end

local layerBarClick = function(button,x,z) --touch map layer bar function
  local layerBar = tBar.layerBar
  if tTool[button].tool == "Help" then
    window.text"This is the layer bar.\nLeft click any layer here to instantly scroll to it.\nOr use the ctrl and shift keys to select multiple layers, which may then be manipulated by right clickling.\nYou can also scroll the menu up and down using a mouse wheel."
    return
  elseif tMenu.open then
    renderMenu()
    return
  end
  local layer = layerBar.eZ-z+layerBar.sL
  if button == 1 and tBlueprint[layer] then
    if tTimers.shift.pressed then
      if layerBar.prevSelected > 0 then
        layerBar.tSelected = {}
        local bottomSel = math.min(layerBar.prevSelected,layer)
        local topSel = math.max(layerBar.prevSelected,layer)
        for i = bottomSel,topSel do
          layerBar.tSelected[i] = true
        end
        layerBar.selectedAmt = topSel-bottomSel+1
        renderLayerBar()
      end
    elseif tTimers.ctrl.lPressed or tTimers.ctrl.rPressed then
      if layerBar.tSelected[layer] then
        layerBar.tSelected[layer] = nil
        layerBar.selectedAmt = layerBar.selectedAmt-1
        layerBar.prevSelected = layerBar.selectedAmt == 0 and 0 or layer
      else
        layerBar.tSelected[layer] = true
        layerBar.selectedAmt = layerBar.selectedAmt+1
        layerBar.prevSelected = layer
      end
      renderLayerBar()
    else
      layerBar.tSelected = {
        [layer] = true
      }
      scroll(layer,nil,nil,nil,true)
      layerBar.selectedAmt = 1
      layerBar.prevSelected = layer
      renderLayerBar()
    end
  elseif button == 2 then --right click
    if tMenu.open then
      renderMenu()
    else
      if tBlueprint[layer] and not layerBar.tSelected[layer] then
        layerBar.tSelected = {
          [layer] = true
        }
        layerBar.prevSelected = layer
        layerBar.selectedAmt = layer
        scroll(layer)
      end
      tMenu.rightClick.render("layerBar",x,z)
    end
  end
end

function renderLayerBar(fullRefresh) --updates the layer sidebar, optionally redrawing it entirely
  if tMode.hideMenus then
    return
  end
  if not tMode.layerBar then
    return
  end
  local layerBar = tBar.layerBar
  screen:setTextColor(tColors.layerBarText)
  local tSelected = layerBar.tSelected
  screen:setLayer(screen.layers.layerBar)
  tBar.touchMap[layerBar.eX-1][layerBar.eZ] = nil
  tBar.touchMap[layerBar.eX-2][layerBar.eZ] = nil
  screen:delPoint(layerBar.eX-1,layerBar.eZ)
  screen:delPoint(layerBar.eX-2,layerBar.eZ)
  local indicatorLength = #string.format(layerBar.sL)
  for iX = 2,indicatorLength do
    tBar.touchMap[layerBar.eX-iX+1][layerBar.eZ] = layerBarClick
  end
  if fullRefresh then
    screen:drawLine(layerBar.sX,layerBar.sZ,layerBar.eX,layerBar.eZ,tColors.layerBar)
  end
  screen:setCursorPos(layerBar.eX-indicatorLength+1,layerBar.eZ)
  screen:setBackgroundColor(
    layerBar.sL == tTerm.scroll.layer and (tSelected[layerBar.sL] and tColors.layerBarViewSelected or tColors.layerBarViewUnselected) 
    or tSelected[layerBar.sL] and tColors.layerBarSelected 
    or tColors.layerBarUnselected
  )
  screen:write(layerBar.sL)
  local curs = 1
  for layer = layerBar.sL+1,layerBar.eL do
    if tBlueprint[layer] then
      screen:setBackgroundColor(
        layer == tTerm.scroll.layer and (tSelected[layer] and tColors.layerBarViewSelected or tColors.layerBarViewUnselected) 
        or tSelected[layer] and tColors.layerBarSelected 
        or tColors.layerBarUnselected
      )
      screen:setCursorPos(layerBar.sX,layerBar.eZ-curs)
      screen:write(string.match(layer,".$"))
      curs = curs+1
    else
      break
    end
  end
end

function openLayerBar() --renders the layer sidebar and adds it to the touch map
  tMode.layerBar = true
  if tMode.hideMenus then
    return
  end
  local layerBar = tBar.layerBar
  local x = tBar.layerBar.eX
  for y = tBar.layerBar.sL,tBar.layerBar.eL do
    tBar.touchMap[x][y] = layerBarClick
  end
  renderLayerBar(true)
  local canvas = tTerm.canvas
  canvas.eX = canvas.eX-1
  canvas.tX = canvas.eX-canvas.sX
  local view = tTerm.viewable
  view.eX = view.sX+canvas.tX
  renderSideBar()
  scroll()
end

function closeLayerBar() --closes the layer sidebar and removes it from the touch map
  tMode.layerBar = false
  if tMode.hideMenus then
    return
  end
  local canvas = tTerm.canvas
  canvas.eX = canvas.eX+1
  canvas.tX = canvas.eX-canvas.sX
  local view = tTerm.viewable
  view.eX = view.sX+canvas.tX
  local iX = tBar.layerBar.eX
  screen:delPoint(iX-1,tBar.layerBar.eZ,screen.layers.layerBar)
  screen:delPoint(iX-2,tBar.layerBar.eZ,screen.layers.layerBar)
  tBar.touchMap[iX-1][tBar.layerBar.eZ] = nil
  tBar.touchMap[iX-2][tBar.layerBar.eZ] = nil
  for iZ=tBar.layerBar.sZ,tBar.layerBar.eZ do
    tBar.touchMap[iX][iZ] = nil
    screen:delPoint(iX,iZ,screen.layers.layerBar)
  end
  if tMode.grid then
    screen:setLayer(screen.layers.gridBorder)
    screen:setCursorPos(tBar.layerBar.sX,tBar.layerBar.sZ)
    screen:setBackgroundColor(tColors.gridBorder)
    screen:setTextColor(tColors.gridBorderText)
    local gridChar = string.format(tBar.layerBar.sZ-1)
    screen:write(gridChar:sub(#gridChar-1))
  end
  renderSideBar()
  scroll()
end

function renderSideBar() --renders sidebar and fills the touch map with sidebar buttons
  if tMode.hideMenus then
    return
  end
  for iY=1,tTerm.screen.y do
    tBar.touchMap[tTerm.screen.x][iY] = nil
    tBar.touchMap[tTerm.screen.x-1][iY] = nil
  end
  screen:setLayer(screen.layers.sideBar)
  local sizeReduction = tTerm.screen.y < 9+tMenu.main.enabled()
  local posX,posY = tTerm.screen.x,sizeReduction and tTerm.screen.y or tTerm.screen.y-1
  for k,v in pairs(colorKey) do
    if string.match(k,"^[%l%s]$") then
      screen:setBackgroundColor(v)
      screen:setCursorPos(posX,posY)
      screen:write" "
      tBar.touchMap[posX][posY] = function(button)
        if tTool[button].tool == "Help" then
          window.text"This is the color selection. It's used to select what color your current tool draws with"
        else
          tTool[button].color = k
          renderBottomBar()
        end
      end
      posX = posX-1
      if posX < tTerm.screen.x-1 then
        posX = tTerm.screen.x
        posY = posY-1
      end
    end
  end
  screen:setTextColor(tColors.sideBarText)
  screen:setBackgroundColor(tColors.sideBar)
  for i=1,#tMenu.main do
    local menu = tMenu.main[i]
    if type(menu.enabled) == "function" and menu.enabled() 
    or menu.enabled == true then
      screen:setCursorPos(tTerm.screen.x-1,posY)
      screen:write(menu.name:sub(1,2))
      tBar.touchMap[tTerm.screen.x][posY] = function() 
        renderMenu(menu.name)
      end
      tBar.touchMap[tTerm.screen.x-1][posY] = tBar.touchMap[tTerm.screen.x][posY]
      menu.sX = tTerm.screen.x-1-#menu.string
      menu.eX = menu.sX+#menu.string
      menu.lX = menu.eX-menu.sX
      menu.sY = math.ceil(posY-(#menu.items/2))
      menu.eY = math.ceil(posY+(#menu.items/2))
      menu.lY = menu.eY-menu.sY+1
      menu.splits = math.ceil(menu.lY/tTerm.screen.y)
      if menu.splits <= 1 then
        while menu.sY < 1 do
          menu.sY = menu.sY+1
          menu.eY = menu.eY+1
        end
        while menu.eY > tTerm.screen.y do
          menu.sY = menu.sY-1
          menu.eY = menu.eY-1
        end
      else
        menu.sY = 1
        menu.eY = math.ceil(menu.lY/menu.splits)
        menu.lY = menu.eY
        menu.sX = menu.sX-(menu.lX*(menu.splits-1))
      end
      posY = posY-1
    end
  end
  if posY > 0 then
    screen:drawLine(tTerm.screen.x,1,tTerm.screen.x,posY,tColors.sideBar)
    screen:drawLine(tTerm.screen.x-1,1,tTerm.screen.x-1,posY,tColors.sideBar)
    if posY >= 2 then
      screen:setCursorPos(tTerm.screen.x-1,1)
      screen:write"/\\"
      tBar.touchMap[tTerm.screen.x][1] = function(button)
        if tTool[button].tool == "Help" then
          window.text"These buttons are used to change layers up and down. This one goes up one layer, as well as create new ones if they don't exist"
        else
          tBlueprint[tTerm.scroll.layer+1] = tBlueprint[tTerm.scroll.layer+1] or class.layer.new()
          scroll(tTerm.scroll.layer+1)
        end
      end
      tBar.touchMap[tTerm.screen.x-1][1] = tBar.touchMap[tTerm.screen.x][1]
      screen:setCursorPos(tTerm.screen.x-1,2)
      screen:write"\\/"
      tBar.touchMap[tTerm.screen.x][2] = function(button)
        if tTool[button].tool == "Help" then
          window.text"These buttons are used to change layers up and down. This one goes down one layer"
        else
          scroll(tTerm.scroll.layer-1)
        end
      end
      tBar.touchMap[tTerm.screen.x-1][2] = tBar.touchMap[tTerm.screen.x][2]
    end
  end
  local x = sizeReduction and tTerm.screen.x-3 or tTerm.screen.x-1
  screen:setCursorPos(x,tTerm.screen.y)
  screen:setBackgroundColor(colors.white)
  screen:setTextColor(colorKey.S)
  screen:write("S")
  screen:setBackgroundColor(colors.black)
  screen:setTextColor(colorKey.X)
  screen:write("X")
  tBar.touchMap[x][tTerm.screen.y] = function(button)
    if tTool[button].tool == "Help" then
      window.text"This is the scan marker, every block you draw with this will be scanned by the turtle, and saved to the blueprint."
    else
      tTool[button].color = "S"
      renderBottomBar()
    end
  end
  tBar.touchMap[x+1][tTerm.screen.y] = function(button)
    if tTool[button].tool == "Help" then
      window.text"This is the break marker, every block you draw with this will be broken by the turtle."
    else
      tTool[button].color = "X"
      renderBottomBar()
    end
  end
  if tBar.menu.sizeReduction ~= sizeReduction then --if the reduction has changed state, the bottom bar must be re-rendered
    tBar.menu.sizeReduction = sizeReduction
    renderBottomBar()
  end
end

function scroll(layer,x,z,absolute,forceRefresh) --scrolls the canvas x and z on layer, if absolute is given, it will scroll to those coordinates
  if not (layer or x or z) then
    --re-renders current view if no args are given
    tTerm.scroll.layer = math.min(#tBlueprint,math.max(tTerm.scroll.layer,1))
    tBlueprint[tTerm.scroll.layer]:render()
    return
  end
  local oldX,oldZ = tTerm.scroll.x,tTerm.scroll.z
  x = x or 0
  z = z or 0
  layer = layer or tTerm.scroll.layer
  if absolute then
    tTerm.scroll.x = math.max(x,0)
    tTerm.scroll.z = math.max(z,0)
  else
    tTerm.scroll.x = math.max(tTerm.scroll.x+x,0)
    tTerm.scroll.z = math.max(tTerm.scroll.z+z,0)
  end
  if oldX ~= tTerm.scroll.x or oldZ ~= tTerm.scroll.z or layer ~= tTerm.scroll.layer or forceRefresh then
    if layer ~= tTerm.scroll.layer and tBlueprint[layer] then
      tTerm.scroll.layer = math.max(layer,1)
      tBar.layerBar.tSelected = {
        [tTerm.scroll.layer] = true
      }
      tBar.layerBar.prevSelected = tTerm.scroll.layer
      tBar.layerBar.selectedAmt = 1
      renderLayerBar()
    end
    local view = tTerm.viewable
    view.sX = tTerm.scroll.x+1
    view.eX = view.sX+tTerm.canvas.tX
    view.sZ = tTerm.scroll.z+1
    view.eZ = tTerm.viewable.sZ+tTerm.canvas.tZ
    tBlueprint[tTerm.scroll.layer]:render()
    renderBottomBar()
    renderToolOverlay()
  end
end

function renderToolOverlay() --renders all tool overlays
  screen:clearLayer(screen.layers.toolsOverlay)
  screen:setLayer(screen.layers.toolsOverlay)
  local view = tTerm.viewable
  local mX = view.mX
  local mZ = view.mZ
  local t = tTool.clipboard or (tTool.shape.eX and tTool.shape)
  if t then
    local sX = math.min(t.sX,t.eX)
    local eX = math.max(t.eX,t.sX)
    local sZ = math.min(t.sZ,t.eZ)
    local eZ = math.max(t.eZ,t.sZ)
    for iX = math.max(sX,view.sX),math.min(eX,view.eX) do
      for iZ = math.max(sZ,view.sZ),math.min(eZ,view.eZ) do 
        local block = t.l[iX-sX+1][iZ-sZ+1]
        if block ~= " " then
          screen:drawPoint(iX-tTerm.scroll.x+mX,iZ-tTerm.scroll.z+mZ,colorKey[block],block == "X" and block)
        end
      end
    end
  end
  t = tTool.select
  if t.sX
  and t.layer == tTerm.scroll.layer then
    screen:clearLayer(screen.layers.toolsOverlay)
    screen:setLayer(screen.layers.toolsOverlay)
    local sX = t.sX >= view.sX and t.sX <= view.eX and t.sX-tTerm.scroll.x+mX
    local sZ = t.sZ >= view.sZ and t.sZ <= view.eZ and t.sZ-tTerm.scroll.z+mZ
    local eX = t.eX and t.eX >= view.sX and t.eX <= view.eX and t.eX-tTerm.scroll.x+mX
    local eZ = t.eX and t.eZ >= view.sZ and t.eZ <= view.eZ and t.eZ-tTerm.scroll.z+mZ
    local color = tColors.selection
    if sX then
      if sZ then
        screen:drawPoint(sX,sZ,color)
        if eX then
          screen:drawPoint(eX,sZ,color)
          if eZ then
            screen:drawPoint(sX,eZ,color)
            screen:drawPoint(eX,eZ,color)
          end
        elseif eZ then
          screen:drawPoint(sX,eZ,color)
        end
      elseif eZ then
        screen:drawPoint(sX,eZ,color)
        if eX then
          screen:drawPoint(eX,eZ,color)
        end
      end
    elseif sZ then
      if eX then
        screen:drawPoint(eX,sZ,color)
        if eZ then
          screen:drawPoint(eX,eZ,color)
        end
      end
    elseif eX and eZ then
      screen:drawPoint(eX,eZ,color)
    end
  end
end

function writePoint(x,z) --renders the specified blueprint point at wherever the cursor is
  local marker,bColor,tColor
  local color = tBlueprint[tTerm.scroll.layer][x][z]
  if color == "X" then
    marker = "X"
    tColor = colorKey.X
    bColor = colors.white
  elseif color == "S" then
    marker = "S"
    tColor = colorKey.S
    bColor = colors.white
  elseif tMode.backgroundLayer and color == " " and (tMode.backgroundLayer[x][z] ~= " " and tMode.backgroundLayer[x][z] ~= "X") then
    marker = tMode.grid and "+" or " "
    bColor = tColors.backgroundLayer
    tColor = colorKey[tMode.backgroundLayer[x][z]] ~= tColors.gridMarker and tColors.gridMarker or tColors.gridMaker2
  elseif tMode.builtRender and color:match"%u" then
    marker = "B"
    tColor = tColors.builtMarker
  elseif tMode.grid then
    marker = "+"
    tColor = colorKey[color] ~= tColors.gridMarker and tColors.gridMarker or tColors.gridMarker2
  end
  screen:drawPoint(nil,nil,bColor or colorKey[color],marker or " ",tColor)
end

function renderPoint(x,z,skipScroll) --renders the given point on screen
  local view = tTerm.viewable
  local pX,pZ
  if skipScroll then
    pX = x-tTerm.scroll.x
    pZ = z-tTerm.scroll.z
  else
    pX = x
    pZ = z
    x = x+tTerm.scroll.x
    z = z+tTerm.scroll.z
  end
  screen:setLayer(screen.layers.canvas)
  screen:setCursorPos(pX+view.mX,pZ+view.mZ)
  writePoint(x,z)
end

function renderArea(x1,z1,x2,z2,skipScroll) --renders the specified area of the blueprint on screen
  layer = layer or tBlueprint[tTerm.scroll.layer]
  local view = tTerm.viewable
  if not skipScroll then
    x1 = x1+tTerm.scroll.x
    z1 = z1+tTerm.scroll.z
    x2 = x2+tTerm.scroll.x
    z2 = z2+tTerm.scroll.z
  end
  screen:setLayer(screen.layers.canvas)
  for iX = math.max(math.min(x1,x2),view.sX),math.min(math.max(x2,x1),view.eX) do
    for iZ = math.max(math.min(z1,z2),view.sZ),math.min(math.max(z2,z1),view.eZ) do
      screen:setCursorPos(iX-tTerm.scroll.x+view.mX,iZ-tTerm.scroll.z+view.mZ)
      writePoint(iX,iZ)
    end
  end
end

function drawPoint(x,z,color,layer,skipScroll,ignoreOverwrite) --renders the point on screen as well as adding it to the blueprint
  local layer = tBlueprint[layer or tTerm.scroll.layer]
  color = tMode.builtDraw and color:upper() or color
  if not skipScroll then
    x = x+tTerm.scroll.x
    z = z+tTerm.scroll.z
  end
  if not tMode.overwrite and not ignoreOverwrite and color ~= " " and layer[x+tTerm.scroll.x][z+tTerm.scroll.z] ~= " " then
    return
  end
  layer[x][z] = (color ~= " " and color) or nil
  renderPoint(x,z,color,true)
end

--[[----------------------------------------------------------------------------------------------------------
Input functions
----------------------------------------------------------------------------------------------------------]]--
local activeInputs = 0 --amount of windows open
inputOpen = false --whether an input window is currently open or not
local inputDefaults = { --default values for tInputFields tables passed to the input function
  name = "", --text on the side of the field
  accepted = ".", --accepted input pattern
  value = "", --value already inputted
  charLimit = math.huge, --amount of characters allowed
  backgroundColor = tColors.inputBar,
  textColor = tColors.inputText,
  nameColor = tColors.inputBoxText
}
local animationDefaults = { --default animation values for animated text
  text = "",
  bColor = tColors.inputBox, --backgroundColor
  tColor = tColors.inputBoxText, --textColor
  renderTime = 1 --time before next frame
}
local scrollDefaults = { --default values for scroll selections
  text = "",
  sText = tColors.scrollBoxSelectText, --selected text color
  sBackground = tColors.scrollBoxSelected, --selected text background color
  uText = tColors.scrollBoxSelectText, --unselected text color
  uBackground = tColors.scrollBoxUnselected, --unselected text background color
  selected = false --selected by default
}
window = {
  text = function(text,tButtonFields,tInputFields,customEvent,reInput)
    local screenLayer = screen.layers.dialogue+activeInputs
    inputOpen = true
    screen:setLayer(screenLayer)
    activeInputs = activeInputs+1
    tInputFields = tInputFields or {}
    --set up text
    local lineLength = tTerm.screen.x-2 --max line length
    local animated = false
    local textColor
    local maxLines = tTerm.screen.y-3-#tInputFields
    if type(text) == "table" then
      if type(text[1]) == "table" then --animation
        animated = true
        text.activeFrame = 1
        for i,frame in ipairs(text) do
          setmetatable(frame,{__index = animationDefaults})
          frame.lines = string.lineFormat(frame.text,lineLength,true)
        end
      else --plain text
        text = {
          lines = string.lineFormat(table.concat(text,"\n"),lineLength,true),
          tColor = text.tColor or tColors.inputBoxText,
          bColor = text.bColor or tColors.inputBox
        }
      end
    else--converts to table if it's not a table
      text = {
        lines = string.lineFormat(text,lineLength,true),
        tColor = tColors.inputBoxText,
        bColor = tColors.inputBox
      }
    end
    local tLine = ""
    if animated then 
      for i,frame in ipairs(text) do
        if #frame.lines > #tLine then
          tLine = frame.lines
          tLine.text = frame.text
        end
      end
      if #tLine > maxLines then
        error("Screen too small for animation",2)
      end
      glasses.log.write(tLine.text)
    else
      tLine = text.lines
      if #tLine > maxLines then
        local windowLines = {}
        for i=#tLine-maxLines+1,#tLine do
          windowLines[#windowLines+1] = tLine[i]
          tLine[i] = nil
        end
        window.text(table.concat(tLine),{"Ok"}) --omg recursion
        screen:setLayer(screenLayer)
        tLine = windowLines
      end
    end
    --default input fields
    local tInputs = {}
    for i=1,#tInputFields do
      if type(tInputFields[i]) ~= "table" then
        tInputs[i] = {
          name = tInputFields[i]
        }
        tInputFields[i] = {
          name = tInputFields[i]
        }
      else
        tInputs[i] = {}
        for k,v in pairs(tInputFields[i]) do
          tInputs[i][k] = v
        end
      end
      local field = tInputs[i]
      if field.value and type(field.value) == "number" then
        field.value = string.format(field.value)
      end
      setmetatable(field,
        {
          __index = inputDefaults
        }
      )
    end
    --default buttons
    local tButtons = {}
    if type(tButtonFields) == "string" then
      tButtons = {
        [1] = tButtonFields
      }
    elseif not tButtonFields or #tButtonFields < 1 then
      tButtons = {
        [1] = "Ok"
      }
    else
      for k,v in pairs(tButtonFields) do
        tButtons[k] = v
      end
    end
    local oldHandlers = eventHandler.active--stores currently in use event handlers, prior to switch
    local eventQueue = {} --unrelated events which occurred during the dialogue
    local prevBlink = screen:getBlink()
    screen:setCursorBlink(false)
    local function endExecution(event)
      --closes input box and returns event and the values in the input fields
      eventHandler.switch(oldHandlers,true)
      local tRes = {}
      for iR=1,#tInputs do
        tRes[tInputs[iR].name] = tInputs[iR].value ~= "-" and tonumber(tInputs[iR].value) or #tInputs[iR].value > 0 and tInputs[iR].value
      end
      screen:setCursorBlink(false)
      if reInput then
        for i=1,#tInputFields do
          for k,v in pairs(tRes) do
            if k == tInputFields[i].name then
              tInputFields[i].value = v
              break
            end
          end
        end
        reInput = function(reText) --set up reInput function
          return window.text(reText,tButtonFields,tInputFields,customEvent,true)
        end
      end
      screen:setCursorBlink(prevBlink)
      screen:delLayer(screenLayer)
      inputOpen = (screenLayer ~= screen.layers.dialogue)
      activeInputs = activeInputs-1
      for i=1,#eventQueue do
        os.queueEvent(unpack(eventQueue[i]))
      end
      return event,tRes,reInput
    end
    --render box
    local box = {
      height = #tLine+2+#tInputs,
      width = tTerm.screen.x-2
    }
    box.top = math.ceil(tTerm.screen.yMid-(box.height/2))
    box.bottom = box.height+box.top
    if box.top < 1 then
      box.bottom = box.bottom+(1-box.top)
      box.top = 1
    end
    screen:drawBox(2,box.top,tTerm.screen.x-1,box.bottom,tColors.inputBox)
    screen:drawFrame(1,box.top,tTerm.screen.x,box.bottom,tColors.inputBoxBorder)
    --write text
    screen:setBackgroundColor(tColors.inputBox)
    screen:setTextColor(tColors.inputBoxText)
    for i,line in ipairs(tLine) do
      screen:setCursorPos(2,box.top+i)
      screen:write(line)
    end
    --set up & render buttons
    local totalButtonSpace = 0
    local buttonTouchMap = class.matrix.new(2)
    for i=1,#tButtons do
      tButtons[i] = {
        name = tButtons[i]
      }
      tButtons[i].size = #tButtons[i].name+2
      totalButtonSpace = totalButtonSpace+tButtons[i].size+2
    end
    local nextButton = math.ceil(tTerm.screen.xMid-(totalButtonSpace/2)+2)
    screen:setTextColor(tColors.inputButtonText)
    screen:setBackgroundColor(tColors.inputButton)
    for i=1,#tButtons do
      tButtons[i].sX = nextButton
      tButtons[i].eX = nextButton+tButtons[i].size-1
      tButtons[i].y = box.bottom-1
      screen:setCursorPos(tButtons[i].sX,tButtons[i].y)
      screen:write(" "..tButtons[i].name.." ")  --add spaces for appearances
      for iX=tButtons[i].sX,tButtons[i].eX do
        buttonTouchMap[iX][tButtons[i].y] = tButtons[i].name
      end
      nextButton = nextButton+#tButtons[i].name+3
    end
    --set up & render input boxes
    local inputTouchMap = class.matrix.new(2)
    if #tInputs > 0 then
      for i=#tInputs,1,-1 do
        local field = tInputs[i]
        screen:setBackgroundColor(tColors.inputBox)
        screen:setTextColor(field.nameColor)
        screen:setCursorPos(3,box.bottom-2-#tInputs+i)
        screen:write(field.name..":")
        field.sX,field.y = screen:getCursorPos() -- input area start x point
        field.eX = tTerm.screen.x-2 --end x point
        field.lX = field.eX-field.sX --total field length
        screen:setTextColor(field.textColor)
        screen:setBackgroundColor(field.backgroundColor)
        screen:write(string.sub(field.value,1,field.lX))
        field.cX = (screen:getCursorPos())-field.sX --cursor pos
        field.scroll = math.max(0,#field.value-field.lX) --scroll value
        screen:drawLine(field.cX+field.sX,field.y,field.eX,field.y,field.backgroundColor)
        for iX = field.sX,field.eX do
          inputTouchMap[iX][field.y] = i
        end
      end
      screen:setCursorBlink(true)
      tInputs.enabled = 1
      screen:setCursorPos(tInputs[1].cX+tInputs[1].sX,tInputs[1].y)
    end
    local function refreshField(field)
     --updates input fields
      screen:setLayer(screenLayer)
      field = tInputs[field]
      field.scroll = (
        field.cX > field.lX 
        and math.min(field.scroll+(field.cX-field.lX),#field.value-field.lX)
        or field.cX < 0
        and math.max(field.scroll-math.abs(field.cX),0)
        or field.scroll
      )
      field.cX = math.max(0,math.min(field.cX,field.lX))
      local fieldString = field.value:sub(field.scroll+1,field.lX+field.scroll+1)
      screen:setCursorPos(field.sX,field.y)
      screen:setBackgroundColor(field.backgroundColor)
      screen:write(fieldString..string.rep(" ",math.max(0,field.lX-#fieldString+1)))
      screen:setCursorPos(field.sX+field.cX,field.y)
    end
    local eventHandlers = {
      mouse_click = function(tEvent)
        local x,y = tEvent[3],tEvent[4]
        if inputTouchMap[x][y] then --input bar clicked
          tInputs.enabled = inputTouchMap[x][y]
          local enabled = tInputs.enabled
          screen:setCursorPos(math.min(#tInputs[enabled].value+tInputs[enabled].sX,x),y)
          tInputs[enabled].cX = (screen:getCursorPos())-tInputs[enabled].sX
        elseif buttonTouchMap[x][y] then
          return endExecution(buttonTouchMap[x][y])
        end
      end,
      char = function(tEvent)
        if tInputs.enabled then
          local field = tInputs[tInputs.enabled]
          if tEvent[2]:match(field.accepted) and #field.value < field.charLimit then -- check for accepted character and character limit
            local curs = field.cX+field.scroll
            field.value = field.value:sub(1,curs)..tEvent[2]..field.value:sub(curs+1)
            field.cX = field.cX+1
            refreshField(tInputs.enabled)
          end
        end
      end,
      key = function(tEvent)
        local key = tEvent[2]
        if tInputs.enabled then
          local field = tInputs[tInputs.enabled]
          --input box
          if key == 14
          and field.cX > 0 then
            --backspace
            local curs = field.cX+field.scroll
            field.value = field.value:sub(1,curs-1)..field.value:sub(curs+1)
            if field.scroll > 0 then
              field.scroll = field.scroll-1
            else
              field.cX = field.cX-1
            end
          elseif key == 205 then --right arrow
            field.cX = field.cX+1
          elseif key == 203 then --left arrow
            field.cX = field.cX-1
          elseif key == 200 then --up arrow
            tInputs.enabled = math.max(1,tInputs.enabled-1)
          elseif key == 208 then --down arrow
            tInputs.enabled = math.min(#tInputs,tInputs.enabled+1)
          elseif key == 211 then --delete
            local curs = field.cX+field.scroll
            if #field.value <= 1 and curs == 0 then
              field.value = ""
            else
              field.value = field.value:sub(1,curs)..field.value:sub(curs+2)
            end
          elseif key == 207 then --end
            field.cX = field.lX
            field.scroll = #field.value-field.lX
          elseif key == 199 then --home
            field.cX = 1
            field.scroll = 0
          elseif key == 28 then --enter
            if tInputs.enabled == #tInputs then
              return endExecution("Ok")
            else
              tInputs.enabled = tInputs.enabled+1
            end
          end
          refreshField(tInputs.enabled)
        else --no input boxes
          if key == 28 then --enter
            return endExecution("Ok")
          end
        end
      end,
      chat_command = function(tEvent)
        local command = tEvent[2]:lower()
        for i=1,#tButtons do
          if tButtons[i].name:lower() == command then
            return endExecution(tButtons[i].name)
          end
        end
        local tCommand = {}
        for word in command:gmatch"%S+" do
          local num = tonumber(word)
          if num then
            tCommand[#tCommand+1] = num
          else
            tCommand[#tCommand+1] = word:lower()
          end
        end
        if tInputs.enabled then
          local field
          if type(tCommand[1]) == "number" then
            field = math.max(1,math.min(#tInputs,tCommand[1]))
            tInputs[field].value = table.concat(tCommand," ",2)
            refreshField(field)
          else
            for i=1,#tInputs do
              if command:match(tInputs[i].name:lower()) then
                tInputs[i].value = command:match(tInputs[i].name:lower().." (.+)")
                refreshField(i)
                break
              end
            end
          end
        end
      end
    }
    if animated then
      text.timerId = os.startTimer(text[1].renderTime)
      eventHandlers.timer = function(tEvent)
        if tEvent[2] == text.timerId then
          text.activeFrame = text.activeFrame+1
          if text.activeFrame > #text then
            text.activeFrame = 1
          end
          screen:setLayer(screenLayer)
          screen:setBackgroundColor(tColors.inputBox)
          screen:setTextColor(tColors.inputBoxText)
          for i,line in ipairs(text[text.activeFrame].lines) do
            screen:setCursorPos(2,box.top+i)
            screen:write(line)
          end
          text.timerId = os.startTimer(text[text.activeFrame].renderTime)
          return true
        else
          eventQueue[#eventQueue+1] = tEvent
        end
      end
    else
      eventHandler.timer = function(tEvent)
        eventQueue[#eventQueue+1] = tEvent
        return true
      end
    end
    if customEvent then
      for k,v in pairs(customEvent) do
        local mainFunc = eventHandlers[k]
        eventHandlers[k] = function(tEvent)
          local button = v(tEvent)
          if button then
            return endExecution(button)
          end
          if mainFunc then
            return mainFunc(tEvent)
          end
        end
      end
    end
    eventHandler.switch(eventHandlers)
    while true do
    --user interaction begins
      local event,tRes,reInput = eventHandler.pull()
      if type(event) == "string" then
        return event,tRes,reInput
      end
    end
  end,
  scroll = function(text,tItems,multiSelection,customEvent)
    local screenLayer = screen.layers.dialogue+activeInputs
    inputOpen = true
    screen:setLayer(screenLayer)
    activeInputs = activeInputs+1
    local scroll = 0
    local selected
    if multiSelection then
      selected = {}
      for i,v in ipairs(tItems) do
        selected[i] = type(v) == "table" and v.selected and true or nil
      end
    else
      selected = 1
    end
    local oldHandlers = eventHandler.active--stores currently in use event handlers, prior to switch
    local function endExecution(event,selection)
      --closes input box and returns event and the values in the input fields
      eventHandler.switch(oldHandlers,true)
      screen:delLayer(screenLayer)
      inputOpen = (screenLayer ~= screen.layers.dialogue)
      activeInputs = activeInputs-1
      return event, selection
    end
    --set up text
    local lineLength = tTerm.screen.x-2 --max line length
    if type(text) == "table" then --converts text to string if it's a table
      text = table.concat(text,"\n")
    end
    glasses.log.write(text)
    local tLine = string.lineFormat(text,lineLength)
    local maxLines = 3
    if #tLine > maxLines then
      window.text(table.concat(tLine,"\n",maxLines+1))
      tLine[maxLines+1] = nil
    end
    local selectionLength = tTerm.screen.x-5
    for i,selection in ipairs(tItems) do
      tItems[i] = (
        type(selection) == "table"
        and selection
        or {text = selection}
      )
      selection = tItems[i]
      setmetatable(selection,{__index = scrollDefaults})
      local text = string.rep(" ",math.max(0,math.floor((selectionLength-#selection.text)/2)))..selection.text
      selection.string = text..string.rep(" ",math.max(selectionLength-#text,0))
    end
    local touchMap = class.matrix.new(2)
    local box = {
      height = 2+math.min(#tItems+#tLine,tTerm.screen.y-5),
      width = tTerm.screen.x
    }
    box.top = tTerm.screen.yMid-math.ceil(box.height/2)
    box.bottom = box.top+box.height
    screen:drawBox(2,box.top+1,box.width-1,box.bottom-1,tColors.inputBox)
    screen:drawFrame(1,box.top,box.width,box.bottom,tColors.inputBoxBorder)
    screen:setBackgroundColor(tColors.inputBox)
    screen:setTextColor(tColors.inputBoxText)
    for i,line in ipairs(tLine) do
      screen:setCursorPos(tTerm.screen.xMid-math.ceil(#line/2),box.top+i)
      screen:write(line)
    end
    local visibleSelections = tTerm.screen.y-6-#tLine
    local selFunc = (
      multiSelection
      and function(clickX,clickY)
        local newSelection = clickY-box.top-#tLine+scroll
        screen:setLayer(screenLayer)
        if selected[newSelection] then --de selection
          selected[newSelection] = nil
          local selection = tItems[newSelection]
          screen:setTextColor(selection.uText)
          screen:setBackgroundColor(selection.uBackground)
          screen:setCursorPos(4,clickY)
          screen:write(selection.string)
        else --new selection
          selected[newSelection] = true
          local selection = tItems[newSelection]
          screen:setTextColor(selection.sText)
          screen:setBackgroundColor(selection.sBackground)
          screen:setCursorPos(4,clickY)
          screen:write(selection.string)
        end
      end
      or function(clickX,clickY)
        local newSelection = clickY-box.top-#tLine+scroll
        if newSelection == selected then
          return
        end
        screen:setLayer(screenLayer)
        if visibleSelections+scroll >= selected
        and scroll < selected then
          local selection = tItems[selected]
          screen:setTextColor(selection.uText)
          screen:setBackgroundColor(selection.uBackground)
          screen:setCursorPos(4,selected+box.top+#tLine-scroll)
          screen:write(selection.string)
        end
        local selection = tItems[newSelection]
        screen:setTextColor(selection.sText)
        screen:setBackgroundColor(selection.sBackground)
        screen:setCursorPos(4,clickY)
        screen:write(selection.string)
        selected = newSelection
      end
    )
    for i = 1,visibleSelections do
      if not tItems[i] then
        break
      end
      local iY = i+box.top+#tLine
      for iX = 4,#tItems[i].string+4 do
        touchMap[iX][iY] = selFunc
      end
    end
    local function refresh()
      screen:setLayer(screenLayer)
      for iY=1+scroll,scroll+visibleSelections do
        if not tItems[iY] then
          return
        end
        local y = box.top+#tLine+iY-scroll
        screen:setCursorPos(4,y)
        if multiSelection then
          screen:setBackgroundColor(selected[iY] and tItems[iY].sBackground or tItems[iY].uBackground)
          screen:setTextColor(selected[iY] and tItems[iY].sText or tItems[iY].uText)
        else
          screen:setBackgroundColor(selected == iY and tItems[iY].sBackground or tItems[iY].uBackground)
          screen:setTextColor(selected == iY and tItems[iY].sText or tItems[iY].uText)
        end
        screen:write(tItems[iY].string)
      end
    end
    refresh()
    local y = box.bottom-1
    local x = tTerm.screen.xMid-6
    screen:setCursorPos(x,y)
    screen:setBackgroundColor(tColors.inputButton)
    screen:setTextColor(tColors.inputButtonText)
    screen:write(" Cancel ")
    screen:setCursorPos(x+9)
    screen:write(" Ok ")
    local cancelFunc = function()
      return endExecution("Cancel")
    end
    local okFunc = (
      multiSelection
      and function()
        local tSelected = {}
        for k in pairs(selected) do
          tSelected[#tSelected+1] = tItems[k].text
        end
        return endExecution("Ok",tSelected)
      end
      or function()
        return endExecution("Ok",tItems[selected].text)
      end
    )
    for i = x,x+7 do
      touchMap[i][y] = cancelFunc
    end
    for i = x+9,x+12 do
      touchMap[i][y] = okFunc
    end
    local eventHandlers = {
      mouse_click = function(tEvent)
        local x,y = tEvent[3],tEvent[4]
        local func = touchMap[x][y]
        if func then
          return func(x,y)
        end
      end,
      mouse_scroll = function(tEvent)
        local oldScroll = scroll
        scroll = math.max(0,math.min(scroll+tEvent[2],#tItems-visibleSelections))
        if scroll ~= oldScroll then
          refresh()
        end
      end,
      key = function(tEvent)
        local key = tEvent[2]
        if key == 28 then
          return endExecution("Ok",selected)
        end
      end
    }
    if customEvent then
      for k,v in pairs(customEvent) do
        local mainFunc = eventHandlers[k]
        eventHandlers[k] = function(tEvent)
          local customEvent = v(tEvent)
          if button then
            return endExecution(customEvent,selected)
          end
          if mainFunc then
            return mainFunc(tEvent,selected)
          end
        end
      end
    end
    eventHandler.switch(eventHandlers)
    while true do
    --user interaction begins
      local event,selection = eventHandler.pull()
      if type(event) == "string" then
        return event,selection
      end
    end
  end
}
--[[----------------------------------------------------------------------------------------------------------
Common inputs
----------------------------------------------------------------------------------------------------------]]--
local colorSelect = {}
for k,v in pairs(colors) do
  if type(v) == "number" then
    k = k:gsub("(%u)",function(l) return " "..l:lower() end)
    k = k:sub(1,1):upper()..k:sub(2)
    colorSelect[#colorSelect+1] = {
      text = k,
      uText = v ~= tColors.scrollBoxSelectText and tColors.scrollBoxSelectText or colors.black,
      uBackground = v
    }
  end
end
dialogue = {
  selectTurtle = function(text,multi)
    local connected = {}
    for k,v in pairs(tMode.sync.ids) do
      if v == "turtle" then
        connected[#connected+1] = k.." - Turtle"
      end
    end
    local ids,button
    if #connected > 1 then
      button,ids = window.scroll(text,connected,multi)
      if button == "Cancel" then
        return false
      end
    else
      ids = connected
    end
    local retIDs = {}
    local nID
    for i,id in ipairs(ids) do
      nID = tonumber(id:match"%d+")
      retIDs[nID] = true
    end
    return retIDs, multi and #ids or nID
  end,
  selectColor = function(text)
    local event,selected = window.scroll(text,colorSelect)
    if event ~= "Cancel" then
      selected = selected:lower()
      local space = selected:find" "
      if space then
        selected = selected:sub(1,space-1)..string.upper(selected:sub(space+1,space+1))..selected:sub(space+2)
      end
      return selected
    end
    return event
  end,
  save = function(text)
    local fileName = tFile.blueprint
    local button,tRes,reInput
    if not fileName then
      button, tRes, reInput = window.text(
        text or "No file name for current blueprint,",
        {
          "Cancel",
          "Ok"
        },
        {
          {
            name = "File name",
            value = "/",
            accepted = "."
          },
        },
        false,
        true
      )
    end
    while button and button ~= "Cancel" do
      fileName = not tFile.blueprint and tRes["File name"] or fileName
      if not fileName then
        button,tRes,reInput = reinput("Invalid file name!")
      elseif fs.exists(fileName..".TAb") then
        button = window.text(
          fileName.." already exists!\n Overwrite?",
          {
            "Cancel",
            "Overwrite"
          }
        )
        if button == "Overwrite" or button == "Ok" then
          break
        end
        button,tRes,reInput = reInput("Overwrite of "..fileName.." cancelled. Input new file name.")
      else
        break
      end
    end
    if button == "Cancel" then
      return false
    end
    tBlueprint:save(fileName)
    tFile.blueprint = fileName
    window.text("Successfully saved "..fileName..".TAb.")
    return true
  end
}


--[[----------------------------------------------------------------------------------------------------------
Turtle functions
----------------------------------------------------------------------------------------------------------]]--
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
    local button, tRes = window.scroll(
      "Select layers to build",
      tSelection,
      true
    )
    if button ~= "Cancel" then
      tProgress.layers = {}
      for i,v in ipairs(tRes) do
        tProgress.layers[i] = tonumber(v)
      end
    else
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
        "Cancel",
        "Ok"
      }
    )
    tProgress.breakMode = (button == "Ok")
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
  local tOngoing = not auto and checkProgress(tFile.blueprint) or loadProgress(tFile.blueprint)
  if not tOngoing then
    return
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
  local function moveTo(nL,nX,nZ)
    cTurtle.moveTo(tOngoing.y + tonumber(dirY..nL-1),"Y",tOngoing.breakMode and digSlot)
    cTurtle.moveTo(tOngoing.x + tonumber(dirX..nX-1),"X",tOngoing.breakMode and digSlot)
    cTurtle.moveTo(tOngoing.z + tonumber(dirZ..nZ-1),"Z",tOngoing.breakMode and digSlot)
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
            blueprint:save(tFile.blueprint,true)
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
            else
              cTurtle.drop("Y-",false,64)
            end
            cTurtle.dig(blockAbove and revBuildDir or buildDir)
            blueprint[nL][nX][nZ] = nil
            blueprint:save(tFile.blueprint,true)
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
              blueprint:save(tFile.blueprint,true)
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
              blueprint:save(tFile.blueprint,true)
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
          if blockAbove then
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
	if tMode.sync.amount > 0 then
	  rednet.send(tMode.sync.ids,"Turtle status",{type = "Build complete", blueprintName = tFile.blueprint})
	end
end

--[[----------------------------------------------------------------------------------------------------------
Event handlers
----------------------------------------------------------------------------------------------------------]]--
eventHandler = loadFile(tFile.eventHandlerFolder.."/eventHandler.Lua")
local execution = function()
  while rawget(screen,1) do
    screen:delLayer(1)
  end
  eventHandler.switch(eventHandler.main)
  tBlueprint[1] = tBlueprint[1] or class.layer.new()
  tTimers.blink.start()
  tTimers.blink.toggle = true
  renderSideBar()
  --renderBottomBar() --sidebar calls this on the first call anyways.
  if tMode.grid then
    renderGrid()
  end
  if tMode.layerBar then
    openLayerBar()
  end
  tBlueprint[tTerm.scroll.layer]:render()
  if turtle and tArg[2] == "-r" then
    build(tBlueprint,true)
    tArg[2] = nil
  end
  while true do
    eventHandler.pull()
  end
end
--[[----------------------------------------------------------------------------------------------------------
Error handling
----------------------------------------------------------------------------------------------------------]]--
local function Quit()
  if tMode.sync.amount > 0 then
    rednet.send(tMode.sync.ids,"Sync OFF")
  end
  if glasses.bridge then
    glasses.bridge.clear()
  end
  if modem then
    modem.close(modemChannel)
  end
  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.black)
  term.clear()
  term.setCursorPos(1,1)
  print"Thank you for using Turtle Architect, by CometWolf."
end
while true do
  local tRes = {pcall(execution)}
  if not tRes[1] then
    if tRes[2] == "Update" then
      os.reboot()
    elseif tRes[2] == "Exit"
    or tRes[2] == "Terminated" then
      return Quit()
    elseif tArg[2] == "-r" then
      --recovery mode ignores errors
    elseif tTerm.color then --color supported crash
      local errors = ""
      local button = window.text(
        "Turtle Architect has encountered an unexpected error:\n"..tostring(tRes[2]).."\n\nPlease report this to CometWolf immediately!",
        {
          "Ignore",
          "Save & quit",
          "Quit"
        }
      )
      if button == "Quit" then
        return Quit()
      elseif button == "Save & quit" then
        dialogue.save()
        return Quit()
      end
    else --non color supported crash
      error(tRes[2])
    end
  else
    return tRes[2]
  end
end