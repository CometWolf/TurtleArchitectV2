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
tFile.folder = tFile.program:match"^(.+/).-$".."/TAFiles" --program files folder
tFile.classFolder = tFile.folder.."/Classes" --classes folder
tFile.menuFolder = tFile.folder.."/Menus" --menu tables folder
tFile.mainMenuFolder = tFile.menuFolder.."/mainMenus" --main menus folder
tFile.toolFolder = tFile.folder.."/Tools" --tools folder
tFile.eventHandlerFolder = tFile.folder.."/EventHandlers"
tFile.cTurtle = "/cTurtle" --cTurtle API,downloaded automatically if missing on a turtle.
tFile.settings = tFile.folder.."/settings.Lua" --settings file
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
    sleepTime = 0,
    sleep = function(time)
    --refreshes screen if more than 1 second of sleep time has elapsed
      os.sleepTime = os.sleepTime+time
      if os.sleepTime > 1 then
        screen:refresh()
        os.sleepTime = 0
      end
      G.sleep(time)
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
      if num+0.5 > math.ceil(num) then
        return math.ceil(num)
      else
        return math.floor(num)
      end
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
    end
  },
  {
    __index = _G.string
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
        input("Failed to connect to computer ID "..id..".")
      end,
      time,
      function(id)
        input("Computer ID "..id.." denied your connection request")
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
        tMode.sync.turtles = tMode.sync.ids == "turtle" and tMode.sync.turtles-1 or tMode.sync.turtles
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
  prep = function()
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.white)
  end,
  pause = function()
    while true do
      local tEvent = {os.pullEventRaw()}
      if tEvent[1] == "key" then
        if tEvent[2] == 14 then
          error()
        else
          return
        end
      elseif tEvent[2] == "timer" then
        os.queueEvent(unpack(tEvent))
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
function loadFile(path,env) --custom file loader, sets environment, handles errors and runs file and returns results
  if not path then
    return
  end
  assert(fs.exists(path),"Error: Attempted to load non-existent file "..path.."!")
  local tRes = {loadfile(path)}
  if not tRes[1] then
    error("The following error occured while loading "..path..": "..tRes[2])
  end
  local func = setfenv(tRes[1],progEnv)
  tRes = {pcall(func)}
  if not tRes[1] then
    error("The following error occured while loading "..path..":\n"..tRes[2])
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
tTerm.screen.xMid = tTerm.screen.x/2
tTerm.screen.yMid = tTerm.screen.y/2
tTerm.canvas.sX = 1
tTerm.canvas.eX = tTerm.screen.x-2
tTerm.canvas.tX = tTerm.canvas.eX-tTerm.canvas.sX+1
tTerm.canvas.sZ = 1
tTerm.canvas.eZ = tTerm.screen.y-1
tTerm.canvas.tZ = tTerm.canvas.eZ-tTerm.canvas.sZ+1
tTerm.viewable.sX = 1
tTerm.viewable.eX = tTerm.canvas.tX
tTerm.viewable.sZ = 1
tTerm.viewable.eZ = tTerm.canvas.tZ
tTerm.viewable.mX = 0
tTerm.viewable.mZ = 0
tTerm.scroll.x = 0
tTerm.scroll.z = 0
tTerm.scroll.layer = 1
tTerm.color = term.isColor()

tOngoing = { --stores ongoing build info
  dir = {}, --stores build directions
  breakMode = false --whether turtle will break obstructions automatically.
}

screen = class.screenBuffer.new() --screen buffer, supports layers and uses custom methods, no silly redirect here.
screen.layers = {
  canvas = 1,
  toolsOverlay = 2,
  bottomBar = 3,
  sideBar = 3,
  gridBorder = 3,
  menus = 4,
  dialogue = 5
}

tBar = { --menu bar variables
  menu = {
    open = false,
    touchMap = class.matrix.new(2) --used for open menus
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
glasses.log.open = function(sX,sY,eX,eY)
  glasses.log.lines = {
    background = glasses.bridge.addBox(sX,sY,eX-sX,eY-sY,tColors.glass.log)
  }
  for i = sY,eY,10 do
    glasses.log.lines[#glasses.log.lines+1] = glasses.bridge.addText(sX,i," ",tColors.glass.logText)
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
	glasses.log.lineLength = math.floor((eX-sX)/10)
  glasses.log.refresh()
end

glasses.log.write = function(text)
  table.insert(glasses.log,1,text)
  glasses.log[glasses.log.maxSize+1] = nil
  if glasses.screenMode:match"Log" then
    glasses.refreshLog()
  end
end

glasses.log.refresh = function()
  local curLine = 1
	local curLog = 1
  while #glasses.log.lines >= curLine and glasses.log[curLog] do
	  local text = glasses.log[curLog]
		while #text > 0 do  --splits text into lines
			local line = text:sub(1,glasses.lineLength)
			local newLine = string.find(line.."","\n") --check for new line character
			if newLine then
				line = line:sub(1,newLine-1)
				text = text:sub(#line+2,#text)
			elseif #line == glasses.lineLength then
				local endSpace = line:find"%s$" or line:find"%s%S-$" or glass.lineLength
				line = line:sub(1,endSpace)
				text = text:sub(#line+1,#text)
			else
				text = ""
			end
			glasses.log.lines[curLine].setText(line)
			curLine = curLine+1
		end
		curLog = curLog+1
	end
end

glasses.log.setOpacity = function(opacity)
  glasses.log.lines.background.setOpacity(opacity)
  for i=1,#glasses.log.lines do
    glasses.log.lines[i].setAlpha(opacity)
  end
  local file = class.fileTable.new(tFile.settings)
  local line = file:find("    opacity = %d%.?%d?%d?d? %-%-log transparency")
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
      end
    end
    if glasses.bridge and modem then
      break
    end
  end
else
  error("Turtle Architect is incompatible with regular computers!",0)
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
function renderBottomBar() --renders bottom bar and updates info
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
  local screenX = tTerm.screen.y > 8+#tMenu.main and tTerm.screen.x-2 or tTerm.screen.x-3
  screen:write(string.rep(" ",math.max(screenX-#coordString-cursX+1,0))..coordString)
  for iX = screenX-#coordString+1,screenX do
    tBar.touchMap[iX][cursY] = function()
      local button, tRes, reInput = input(
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

function renderMenu(menu) --renders the given menu and creates touchmap for said menu
  tMenu.touchMap = class.matrix.new(2)
  screen:clearLayer(4)
  if not menu 
  or not tMenu.main[menu] and menu ~= "rightClick" then
    tMenu.open = false
    return
  elseif tMenu.open then
    tMenu.open = false
  end
  tMenu.open = menu
  if menu == "rightClick" then
    tMenu.rightClick.render()
    return
  end
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
      enabled = (type(enabled) == "function" and enabled() or enabled)
      screen:setBackgroundColor(i%2 == 0 and tColors.menuPri or tColors.menuSec)
      screen:setTextColor(enabled and tColors.enabledMenuText or tColors.disabledMenuText)
      screen:setCursorPos(sX,sY)
      screen:write(menu.items[iMenu].string)
      for iX = sX,sX+menu.lX do
        tMenu.touchMap[iX][sY] = (
          (
            enabled
            and function(button)
              renderMenu()
              menu.items[iMenu].func(button)
            end
          ) or (
            true --true prevents the touchmap func from closing the menu
          )
        )
      end
    end
  end
end

function renderSideBar() --renders sidebar and creates touchmap for sidebar buttons
  screen:setLayer(screen.layers.sideBar)
  local posX,posY = tTerm.screen.x,(tTerm.screen.y > 8+#tMenu.main and tTerm.screen.y-1) or tTerm.screen.y
  for k,v in pairs(colorKey) do
    if #k == 1 and k:match"[%l%s]" then
      screen:setBackgroundColor(v)
      screen:setCursorPos(posX,posY)
      screen:write" "
      tBar.touchMap[posX][posY] = function(button)
        tTool[button].color = k
        renderBottomBar()
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
    if posY > 2 then
      screen:setCursorPos(tTerm.screen.x-1,1)
      screen:write"/\\"
      tBar.touchMap[tTerm.screen.x][1] = function()
        tBlueprint[tTerm.scroll.layer+1] = tBlueprint[tTerm.scroll.layer+1] or class.layer.new()
        scroll(tTerm.scroll.layer+1)
      end
      tBar.touchMap[tTerm.screen.x-1][1] = tBar.touchMap[tTerm.screen.x][1]
      screen:setCursorPos(tTerm.screen.x-1,2)
      screen:write"\\/"
      tBar.touchMap[tTerm.screen.x][2] = function()
        scroll(tTerm.scroll.layer-1)
      end
      tBar.touchMap[tTerm.screen.x-1][2] = tBar.touchMap[tTerm.screen.x][2]
    end
    screen:setCursorPos(tTerm.screen.x-1,tTerm.screen.y)
    screen:setBackgroundColor(colors.black)
    screen:setTextColor(colorKey.X)
    screen:write("XX")
    for i=0,1 do
      tBar.touchMap[tTerm.screen.x-i][tTerm.screen.y] = function(button)
        tTool[button].color = "X"
        renderBottomBar()
      end
    end
  else
    screen:setCursorPos(tTerm.screen.x-2,tTerm.screen.y)
    screen:setBackgroundColor(colors.black)
    screen:setTextColor(colorKey.X)
    screen:write("X")
    tBar.touchMap[tTerm.screen.x-2][tTerm.screen.y] = function(button)
      tTool[button].color = "X"
      renderBottomBar()
    end
  end
end

function scroll(layer,x,z,absolute,forceRefresh) --scrolls the canvas x and z on layer, if absolute is given, it will scroll to those coordinates
  if not (layer or x or z) then
    --re-renders current view if no args are given
    tTerm.scroll.layer = math.min(#tBlueprint,math.max(tTerm.scroll.layer,1))
    tBlueprint[tTerm.scroll.layer]:render()
    renderToolOverlay()
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
    local view = tTerm.viewable
    tTerm.scroll.layer = math.max(layer,1)
    view.sX = tTerm.scroll.x+1
    view.eX = view.sX+tTerm.canvas.tX
    view.sZ = tTerm.scroll.z+1
    view.eZ = tTerm.viewable.sZ+tTerm.canvas.tZ
    tBlueprint[tTerm.scroll.layer]:render()
    renderToolOverlay()
    renderBottomBar()
  end
end

function renderToolOverlay() --renders all tool overlays
  screen:clearLayer(screen.layers.toolsOverlay)
  screen:setLayer(screen.layers.toolsOverlay)
  local view = tTerm.viewable
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
          screen:drawPoint(iX-tTerm.scroll.x+tTerm.viewable.mX,iZ-tTerm.scroll.z+tTerm.viewable.mZ,colorKey[block],block == "X" and block)
        end
      end
    end
  end
  t = tTool.select
  if t.sX
  and t.layer == tTerm.scroll.layer then
    screen:clearLayer(screen.layers.toolsOverlay)
    screen:setLayer(screen.layers.toolsOverlay)
    local x1,z1 = t.sX-tTerm.scroll.x,t.sZ-tTerm.scroll.z
    if t.sX >= view.sX and t.sX <= view.eX
    and t.sZ >= view.sZ and t.sZ <= view.eZ then
      screen:drawPoint(x1,z1,tColors.selection)
    end
    if t.eX then
      local x2,z2 = t.eX-tTerm.scroll.x,t.eZ-tTerm.scroll.z
      if t.eX >= view.sX and t.eX <= view.eX then
        screen:drawPoint(x2,z1,tColors.selection)
        if t.eZ >= view.sZ and t.eZ <= view.eZ then
          screen:drawPoint(x1,z2,tColors.selection)
          screen:drawPoint(x2,z2,tColors.selection)
        end
      elseif t.eZ >= view.sZ and t.eZ <= view.eZ then
        screen:drawPoint(x1,z2,tColors.selection)
      end
    end
  end
end

function writePoint(x,z,color) --renders the specified blueprint point at wherever the cursor is
  local marker,bColor
  color = color or tBlueprint[tTerm.scroll.layer][x][z]
  if color == "X" then
    marker = "X"
    screen:setTextColor(color)
    bColor = colors.white
  elseif tMode.backgroundLayer and color == " " and tMode.backgroundLayer[x][z] ~= " " then
    marker = tMode.grid and "+" or " "
    bColor = tColors.backgroundLayer
  elseif tMode.builtRender and color:match"%u" then
    marker = "B"
    screen:setTextColor(tColors.builtMarker)
  elseif tMode.grid then
    marker = "+"
    screen:setTextColor(colorKey[color] ~= tColors.gridMarker and tColors.gridMarker or tColors.gridMarker2)
  end
  screen:setBackgroundColor(bColor or colorKey[color])
  screen:write(marker or " ")
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
  writePoint(x,z,false)
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

function drawPoint(x,z,color,skipScroll,ignoreOverwrite) --renders the point on screen as well as adding it to the blueprint
  local layer = tBlueprint[tTerm.scroll.layer]
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
Input function
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
function input(text,tButtonFields,tInputFields,customEvent,reInput)
  local screenLayer = screen.layers.dialogue+activeInputs
  inputOpen = true
  if type(customEvent) == "function" then
    error("Correct this you turd",2)
  end
  screen:setLayer(screenLayer)
  activeInputs = activeInputs+1
  tInputFields = tInputFields or {}
  --set up text
  local lineLength = tTerm.screen.x-2 --max line length
  local tLine = {}
  if type(text) == "table" then --converts text to string if it's a table
    text = table.concat(text,"\n")
  end
  while #text > 0 do  --splits text into a table containing each line
    local line = text:sub(1,lineLength)
    local newLine = string.find(line.."","\n") --check for new line character
    if newLine then
      line = line:sub(1,newLine-1)
      text = text:sub(#line+2,#text)
    elseif #line == lineLength then
      local endSpace = line:find"%s$" or line:find"%s%S-$" or lineLength
      line = line:sub(1,endSpace)
      text = text:sub(#line+1,#text)
    else
      text = ""
    end
    tLine[#tLine+1] = line
  end
  local maxLines = tTerm.screen.y-3-#tInputFields
  if #tLine > maxLines then
    input(table.concat(tLine,"\n",maxLines+1),tButtonFields,tInputFields) --omg recursion
    tLine[maxLines+1] = nil
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
  local oldHandlers = {}--stores currently in use event handlers, prior to switch
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
        return input(reText,tButtonFields,tInputFields,customEvent,true)
      end
    end
    screen:delLayer(screenLayer)
    inputOpen = (screenLayer ~= screen.layers.dialogue)
    activeInputs = activeInputs-1
    return event,tRes,reInput
  end
  --render box
  local buttonTouchMap,inputTouchMap
  if tTerm.color then
    local box = {
      height = #tLine+2+#tInputs,
      width = tTerm.screen.x-2
    }
    box.top = math.floor(tTerm.screen.yMid-(box.height/2))
    box.bottom = math.ceil(tTerm.screen.yMid+math.floor(box.height/2))
    screen:drawBox(2,box.top,tTerm.screen.x-1,box.bottom,tColors.inputBox)
    screen:drawFrame(1,box.top,tTerm.screen.x,box.bottom,tColors.inputBoxBorder)
    --write text
    screen:setBackgroundColor(tColors.inputBox)
    screen:setTextColor(tColors.inputBoxText)
    for i=1,#tLine do
      screen:setCursorPos(math.ceil(tTerm.screen.xMid-(#tLine[i]/2))+1,box.top+i)
      screen:write(tLine[i])
    end
    --set up & render buttons
    local totalButtonSpace = 0
    buttonTouchMap = class.matrix.new(2)
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
      tButtons[i].eX = nextButton+tButtons[i].size
      tButtons[i].y = box.bottom-1
      screen:setCursorPos(tButtons[i].sX,tButtons[i].y)
      screen:write(" "..tButtons[i].name.." ")  --add spaces for appearances
      nextButton = nextButton+#tButtons[i].name+2
      for iX=tButtons[i].sX,tButtons[i].eX do
        buttonTouchMap[iX][tButtons[i].y] = tButtons[i].name
      end
    end
    --set up & render input boxes
    inputTouchMap = class.matrix.new(2)
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
        screen:write(field.value)
        field.cX = (screen:getCursorPos())-field.sX --cursor pos
        field.scroll = 0 --scroll value
        screen:drawLine(field.cX+field.sX,field.y,field.eX,field.y,field.backgroundColor)
        for iX = field.sX,field.eX do
          inputTouchMap[iX][field.y] = i
        end
      end
      screen:setCursorBlink(true)
      tInputs.enabled = 1
      screen:setCursorPos(tInputs[1].cX+tInputs[1].sX,tInputs[1].y)
    end
  end
  local function refreshField(field)
   --updates input fields
     screen:setLayer(screenLayer)
    field = tInputs[field]
    if field.cX > field.lX then
      field.scroll = field.scroll+(field.cX-field.lX)
      field.cX = field.lX
    elseif field.cX < 0 then
      field.scroll = math.max(0,field.scroll+field.cX)
      field.cX = 0
    end
    if field.cX+field.scroll > #field.value then
      field.scroll = math.max(0,#field.value-field.lX)
      field.cX = math.max(#field.value-field.scroll,math.min(#field.value,field.lX))
    end
    local fieldString = field.value:sub(field.scroll,field.lX+field.scroll)
    screen:setCursorPos(field.sX,field.y)
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
          field.value = field.value:sub(1,field.cX+field.scroll)..tEvent[2]..field.value:sub(field.cX+field.scroll+1)
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
        and (field.cX > 0 or field.scroll > 0) then
          --backspace
          field.value = field.value:sub(1,field.cX+field.scroll-1)..field.value:sub(field.cX+field.scroll+1)
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
          if #field.value <= 1 and field.cX == 1 then
            field.value = ""
          else
            field.value = field.value:sub(1,field.cX+field.scroll)..field.value:sub(field.cX+field.scroll+2)
          end
        elseif key == 207 then --end
          field.cX = #field.value+1
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
  for k,v in pairs(eventHandler.active) do
    oldHandlers[k] = v
  end
  eventHandler.switch(eventHandlers)
  while true do
  --user interaction begins
    local event,tRes,reInput = eventHandler.pull()
    if event then
      return event,tRes,reInput
    end
  end
end

--[[----------------------------------------------------------------------------------------------------------
Common inputs
----------------------------------------------------------------------------------------------------------]]--
dialogue = {
  save = function(text)
    local fileName = tFile.blueprint
    local button,tRes,reInput
    if not fileName then
      button, tRes, reInput = input(
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
        button,tRes,reInput = reInput("Invalid file name!")
      elseif fs.exists(fileName..".TAb") then
        button = input(
          fileName.." already exists!\n Overwrite?",
          {
            "Cancel",
            "Overwrite"
          }
        )
        if button == "Overwrite" then
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
    input("Successfully saved "..fileName..".TAb.")
    return true
  end
}


--[[----------------------------------------------------------------------------------------------------------
Turtle functions
----------------------------------------------------------------------------------------------------------]]--
function saveProgress(fileName,tProgress)
  local file = class.fileTable.new()
  file:write("sLayer: "..tProgress.sLayer)
  file:write("eLayer: "..tProgress.eLayer)
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
  tOngoing.sLayer = tonumber(line:match"sLayer: (%d+)" or 1)
  line = read()
  tOngoing.eLayer = tonumber(line:match"eLayer: (%d+)" or #tBlueprint)
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
      if turtle.getItemCount(v) > threshold then
        turtle.select(v)
        return true
      end
    end
    if cTurtle.tSettings.enderChest then
      if cTurtle.enderRestock(cTurtle.tSettings.enderChest,tBlueprint.colorSlots[colorNum],tBlueprint.colorSlots[colorNum]) then
        turtle.select(tBlueprint.colorSlots[color][1])
        return true
      end
    end
    local retry = tTimers.restockRetry.start()
    if tMode.sync.amount > 0 then
      rednet.send(tMode.sync.ids,"Turtle status",{type = "Blocks required",color = color, slots = tBlueprint.colorSlots[color][1].."-"..tBlueprint.colorSlots[color][#tBlueprint.colorSlots[color]]})
    end
    local button,tRes = input(
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

function checkUsage(blueprint,sLayer,eLayer)
  --checks amount of materials required to build the given blueprint
  blueprint = blueprint or tBlueprint
  tOngoing.sLayer = sLayer or 1 --start layer
  tOngoing.eLayer = eLayer or #blueprint --end layer
  local tUsage = {
    fuel = 0
  }
  local tPos = {
    x = 0,
    y = 1,
    z = 0
  }
  local placed = class.matrix.new(3)
  for nL = sLayer,eLayer do
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
  end
  return tUsage
end

function assignColorSlots(color)
  local button, tRes, reInput = input(
    "Input slot range for "..keyColor[color],
    {
      "Cancel",
      "Ok",
    },
    {
      {
        name = "From",
        value = tBlueprint.colorSlots[color][1] or 1,
        accepted = "%d",
        charLimit = 2
      },
      {
        name = "To",
        value = tBlueprint.colorSlots[color][#tBlueprint.colorSlots[color]] or 16,
        accepted = "%d",
        charLimit = 2
      },
    },
    false,
    true
  )
  while button ~= "Cancel" do
    if not tRes.From then
      button,tRes,reInput = reInput("Missing parameter From!")
    elseif not tRes.To then
      button,tRes,reInput = reInput("Missing parameter To!")
    elseif tRes.From < 1 or tRes.From > tRes.To
    or tRes.To > 16 then
      button,tRes,reInput = reInput("Invalid slot range "..tRes.From.."-"..tRes.To.."!")
    elseif button == "Ok" then
      tBlueprint.colorSlots[color] = {}
      for i=tRes.From,tRes.To do
        tBlueprint.colorSlots[color][#tBlueprint.colorSlots[color]+1] = i
      end
      return true
    end
  end
  return false
end

function checkProgress(fileName,tProgress,blueprint,auto)
  if fileName
  and fs.exists(fileName..".TAo")
  and not tProgress then
    tProgress = loadProgress(fileName)
    if auto then
      return tProgress
    else
      local button = input(
        [[In-progress build of current blueprint found.
layers ]]..tProgress.sLayer..[[-]]..tProgress.eLayer..[[ 
X: ]]..tProgress.x..[[ "]]..tProgress.dir.x..[["
Y: ]]..tProgress.y..[[ "]]..tProgress.dir.y..[["
Z: ]]..tProgress.z..[[ "]]..tProgress.dir.z..[["
Break mode: ]]..(tProgress.breakMode and "ON" or "OFF")..[[ 
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
  if not (tProgress.sLayer and tProgress.eLayer) then
    local button, tRes, reInput = input(
      "Input layer range to build",
      {
        "Cancel",
        "Ok",
      },
      {
        {
          name = "Start",
          value = 1,
          accepted = "%d"
        },
        {
          name = "End",
          value = #blueprint,
          accepted = "%d"
        },
      },
      false,
      true
    )
    while true do
      if button == "Cancel" then
        input("Construction cancelled.")
        return
      elseif not tRes.Start then
        button,tRes,reInput = reInput("Missing start layer!")
      elseif not tRes.End then
        button,tRes,reInput = reInput("Missing end layer!")
      elseif button == "Ok" then
        tProgress.sLayer = tRes.Start
        tProgress.eLayer = tRes.End
        break
      end
    end
  end
  local blueprint = blueprint or class.blueprint.load(fileName) or tBlueprint
  local tUsage = checkUsage(blueprint,tProgress.sLayer,tProgress.eLayer)
  local fuelUsage = tUsage.fuel
  tUsage.fuel = nil
  for k,v in pairs(tUsage) do
    if not tBlueprint.colorSlots[k][1] then
      if not assignColorSlots(k) then
        input("Construction cancelled.")
        return false
      end
    end
  end
  blueprint:save(fileName or tFile.blueprint)
  if not tProgress.x then
    local button, tRes, reInput = input(
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
        input("Construction cancelled.")
        return
      elseif button == "Cur pos" then
        tRes.X = cTurtle.tPos.x
        tRes.Y = cTurtle.tPos.y
        tRes.Z = cTurtle.tPos.z
      end
      if not tRes.X then
        button,tRes,reInput = reInput("Missing parameter X!")
      elseif not tRes.Y then
        button,tRes,reInput = reInput("Missing parameter Y!")
      elseif not tRes.Z then
        button,tRes,reInput = reInput("Missing parameter Z!")
      elseif button == "Ok" or button == "Cur pos" then
        tProgress.x = tRes.X
        tProgress.y = tRes.Y
        tProgress.z = tRes.Z
        break
      end
    end
  end
  if not tProgress.dir.x then
    local button, tRes, reInput = input(
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
        input("Construction cancelled.")
        return
      elseif not tRes.X then
        button,tRes,reInput = reInput("Missing X direction!")
      elseif not tRes.Y then
        button,tRes,reInput = reInput("Missing Y direction!")
      elseif not tRes.Z then
        button,tRes,reInput = reInput("Missing Z direction!")
      elseif button == "Ok" then
        tProgress.dir.x = tRes.X
        tProgress.dir.y = tRes.Y
        tProgress.dir.z = tRes.Z
        break
      end
    end
  end
  if not tProgress.enderChest and not auto then
    local button, tRes, reInput = input(
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
        button,tRes,reInput = reInput("Invalid slot "..tRes.Slot)
      elseif button == "Ok" then
        tProgress.enderChest = tRes.Slot
        break
      elseif button == "Permanent" then
        tProgress.enderChest = tRes.Slot
        cTurtle.tSettings.enderFuel = tProgress.enderChest
        cTurtle.saveSettings()
        break
      end
    end
  end
  saveProgress(fileName,tProgress)
  return tProgress,fileName
end

function build(blueprint,auto)
  --builds the given blueprint layers
  if not (tFile.blueprint or blueprint) then
    if not dialogue.save"Blueprint must be saved locally prior to building" then
      input"Construction cancelled"
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
  local digSlot = blueprint.colorSlots.X[1]
  local threshold = digSlot and 1 or 2
  for nL = tOngoing.sLayer,tOngoing.eLayer do
    cTurtle.moveTo(tOngoing.y + tonumber(tOngoing.dir.y..nL-1),"Y",tOngoing.breakMode)
    local layerCopy = tBlueprint[nL]:copy() --table copy because fuck you next
    for nX,vX in pairs(layerCopy) do
      for nZ in pairs(vX) do
        local block = tBlueprint[nL][nX][nZ]
        local nX = nX
        while block do
          if block:match"%l" then --unbuilt block
            cTurtle.moveTo(tOngoing.x + tonumber(tOngoing.dir.x..nX-1),"X",tOngoing.breakMode)
            cTurtle.moveTo(tOngoing.z + tonumber(tOngoing.dir.z..nZ-1),"Z",tOngoing.breakMode)
            if not selectColor(block,threshold) then
              input("Construction cancelled.")
              return
            end
            cTurtle.replace("-Y"..tOngoing.dir.y,false,digSlot)
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
            cTurtle.moveTo(tOngoing.x + tonumber(tOngoing.dir.x..nX-1),"X",tOngoing.breakMode)
            cTurtle.moveTo(tOngoing.z + tonumber(tOngoing.dir.z..nZ-1),"Z",tOngoing.breakMode)
            selectColor(block)
            cTurtle.drop("Y-",false,64)
            cTurtle.dig("-Y"..tOngoing.dir.y)
            cTurtle.drop("Y-",false,64)
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
          block = nil
          local nextBlock = {}
          for i=-1,1 do --scan for blocks in vicinity
            for j=-1,1 do
              if blueprint[nL][nX+i][nZ+j]:match"[X%l]" then
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
  eventHandler.switch(eventHandler.main)
  tBlueprint[1] = tBlueprint[1] or class.layer.new()
  tTimers.blink.start()
  tTimers.blink.toggle = true
  renderBottomBar()
  renderSideBar()
  tBlueprint[1]:render()
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
  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.black)
  term.clear()
  term.setCursorPos(1,1)
  print"Thank you for using Turtle Architect, by CometWolf."
end
while true do
  local tRes = {pcall(execution)}
  if not tRes[1] then
    if tRes[2] == "Exit"
    or tRes[2] == "Terminated" then
      return Quit()
    elseif tTerm.color then --color supported crash
      local errors = ""
      local button = input(
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
