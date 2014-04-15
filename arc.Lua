--[[
--------------------------------------------------------------------------------------------------------------
|                                              Turtle Architect                                              |
|                                                by CometWolf                                                |
--------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------------------
Program init
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
          tLines[#tLines+1] = k..": "..tostring(v)
        end
      else
        tLines[#tLines+1] = type(var).." "..(var == true and "true" or var == false and "false")
      end
    end
    local lines = tTerm.screen.y-2
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
File paths
----------------------------------------------------------------------------------------------------------]]--
tFile.folder = tFile.program:match"^(.+/).-$".."/TAFiles" --program files folder
tFile.classFolder = tFile.folder.."/Classes" --classes folder
tFile.menuFolder = tFile.folder.."/Menus" --menu tables folder
tFile.mainMenuFolder = tFile.menuFolder.."/mainMenus" --main menus folder
tFile.toolFolder = tFile.folder.."/Tools" --tools folder
tFile.cTurtle = "/cTurtle" --cTurtle API,downloaded automatically if missing on a turtle.
tFile.settings = tFile.folder.."/settings.Lua" --settings file

--[[----------------------------------------------------------------------------------------------------------
API mods
----------------------------------------------------------------------------------------------------------]]--
os = setmetatable(
  {
    pullEvent = function(sFilter) --refreshes the screen every time pullEvent is used
      screen:refresh()
      return _G.os.pullEvent(sFilter)
    end
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

local sleepTime = 0
sleep = function(time)
  --refreshes screen if more than 1 second of sleep time has elapsed
  sleepTime = sleepTime+time
  if sleepTime > 1 then
    screen:refresh()
    sleepTime = 0
  end
  sleep(time)
end


--[[----------------------------------------------------------------------------------------------------------
Program files loading
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

--class files
class = {}
for _k,file in pairs(fs.list(tFile.classFolder)) do
  class[file:match"(.+)%.Lua"] = loadFile(tFile.classFolder.."/"..file,progEnv)
end

--settings
loadFile(tFile.settings)

--menuTables
--tools are loaded within the Tools menu file
tMenu = {}
for _k,file in pairs(fs.list(tFile.menuFolder)) do
  if not fs.isDir(tFile.menuFolder.."/"..file) then
    tMenu[file:match"(.+)%.Lua"] = loadFile(tFile.menuFolder.."/"..file,progEnv)
  end
end

--[[----------------------------------------------------------------------------------------------------------
Assorted variables
----------------------------------------------------------------------------------------------------------]]--
tPaste = { --pastebin program codes
  program = "WIP"
}

tTerm = { --screen size and viewing area
  screen = {}, --screen size
  canvas = {}, --canvas size
  scroll = {}, --canvas scroll amount
  viewable = {} --currently visible canvas area
}
tTerm.screen.x,tTerm.screen.y = term.getSize()
tTerm.screen.xMid = math.ceil(tTerm.screen.x/2)
tTerm.screen.yMid = math.ceil(tTerm.screen.y/2)
tTerm.canvas.sX = 1
tTerm.canvas.eX = tTerm.screen.x-2
tTerm.canvas.tX = tTerm.canvas.eX-tTerm.canvas.sX
tTerm.canvas.sZ = 1
tTerm.canvas.eZ = tTerm.screen.y-1
tTerm.canvas.tZ = tTerm.canvas.eZ-tTerm.canvas.sZ
tTerm.viewable.sX = 1
tTerm.viewable.eX = tTerm.canvas.tX+1
tTerm.viewable.sZ = 1
tTerm.viewable.eZ = tTerm.canvas.tZ+1
tTerm.viewable.mX = 0
tTerm.viewable.mZ = 0
tTerm.scroll.x = 0
tTerm.scroll.z = 0
tTerm.scroll.layer = 1
tTerm.color = term.isColor()

tBlueprint = class.blueprint.new() --stores current blueprint file

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
  local screenX = tTerm.screen.y > 8+#tMenu.main and tTerm.screen.x or tTerm.screen.x-2
  screen:write(string.rep(" ",screenX-#coordString-cursX+1)..coordString)
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
          scroll(tRes.layer,tRes.X,tRes.Z,true)
          return
        end
      end
    end
  end
end

function renderMenu(menu) --renders the given menu and creates touchmap for said menu
  tMenu.touchMap = class.matrix.new(2)
  screen:delLayer(4)
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
  screen:setTextColor(tColors.menuText)
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
      screen:setBackgroundColor(i%2 == 0 and tColors.menuPri or tColors.menuSec)
      screen:setCursorPos(sX,sY)
      screen:write(menu.items[iMenu].string)
      for iX = sX,sX+menu.lX do
        tMenu.touchMap[iX][sY] = function(button)
          renderMenu()
          menu.items[iMenu].func(button)
        end
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
  if posY > 0 then
    screen:drawLine(tTerm.screen.x,1,tTerm.screen.x,posY,tColors.sideBar)
    screen:drawLine(tTerm.screen.x-1,1,tTerm.screen.x-1,posY,tColors.sideBar)
    if posY > 2 then
      screen:setCursorPos(tTerm.screen.x-1,1)
      screen:write"/\\"
      tBar.touchMap[tTerm.screen.x][1] = function()
        tTerm.scroll.layer = tTerm.scroll.layer+1
        scroll()
      end
      tBar.touchMap[tTerm.screen.x-1][1] = tBar.touchMap[tTerm.screen.x][1]
      screen:setCursorPos(tTerm.screen.x-1,2)
      screen:write"\\/"
      tBar.touchMap[tTerm.screen.x][2] = function()
        tTerm.scroll.layer = tTerm.scroll.layer-1
        scroll()
      end
      tBar.touchMap[tTerm.screen.x-1][2] = tBar.touchMap[tTerm.screen.x][2]
    end
  end
end

function scroll(layer,x,z,absolute) --scrolls the canvas x and z on layer, if absolute is given, it will scroll to those coordinates
  if not (layer or x or z) then
    --re-renders current view if no args are given
    tTerm.scroll.layer = math.min(#tBlueprint,math.max(tTerm.scroll.layer,1))
    tBlueprint[tTerm.scroll.layer]:render()
    renderToolOverlay()
  end
  local oldX,oldZ = tTerm.scroll.x,tTerm.scroll.z
  x = x or 0
  z = z or 0
  layer = layer or tTerm.scroll.layer
  if absolute then
    tTerm.scroll.x = x
    tTerm.scroll.z = z
  else
    tTerm.scroll.x = math.max(tTerm.scroll.x+x,0)
    tTerm.scroll.z = math.max(tTerm.scroll.z+z,0)
  end
  if oldX ~= tTerm.scroll.x or oldZ ~= tTerm.scroll.z or layer ~= tTerm.scroll.layer then
    local view = tTerm.viewable
    tTerm.scroll.layer = layer
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
  screen:delLayer(screen.layers.toolsOverlay)
  screen:setLayer(screen.layers.toolsOverlay)
  local view = tTerm.viewable
  local t = tTool.clipboard or (tTool.circle.eX and tTool.circle)
  if t then
    local sX = math.min(t.sX,t.eX)
    local eX = math.max(t.eX,t.sX)
    local sZ = math.min(t.sZ,t.eZ)
    local eZ = math.max(t.eZ,t.sZ)
    for iX = math.max(sX,view.sX),math.min(eX,view.eX) do
      for iZ = math.max(sZ,view.sZ),math.min(eZ,view.eZ) do 
        local block = t.l[iX-sX+1][iZ-sZ+1]
        if block ~= " " then
          screen:drawPoint(iX-tTerm.scroll.x+tTerm.viewable.mX,iZ-tTerm.scroll.z+tTerm.viewable.mZ,colorKey[block])
        end
      end
    end
  end
  t = tTool.select
  if t.sX then
    screen:delLayer(screen.layers.toolsOverlay)
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
  if tMode.backgroundLayer and color == " " and tMode.backgroundLayer[x][z] ~= " " then
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

function renderPoint(x,z,color,skipScroll) --renders the point on screen, without changing the blueprint
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

function drawPoint(x,z,color,skipScroll) --renders the point on screen as well as adding it to the blueprint
  local layer = tBlueprint[tTerm.scroll.layer]
  color = tMode.builtDraw and color:upper() or color
  if not tMode.overwrite and color ~= " " and layer[x+tTerm.scroll.x][z+tTerm.scroll.z] ~= " " then
    return
  end
  layer[x+(not skipScroll and tTerm.scroll.x or 0)][z+(not skipScroll and tTerm.scroll.z or 0)] = (color ~= " " and color) or nil
  renderPoint(x,z,color,skipScroll)
end

--[[----------------------------------------------------------------------------------------------------------
Input function
----------------------------------------------------------------------------------------------------------]]--
local inputDefaults = { --default values for tInputFields tables passed to the input function
  name = "", --text on the side of the field
  accepted = ".", --accepted input pattern
  value = "", --value already inputted
  backgroundColor = tColors.inputBar,
  textColor = tColors.inputText,
  nameColor = tColors.inputBoxText
}
function input(text,tButtonFields,tInputFields,customEvent,reInput)
  screen:setLayer(screen.layers.dialogue)
  tInputFields = tInputFields or {}
  --set up text
  local lineLength = tTerm.screen.x-2 --max line length
  local tLine = {}
  if type(text) == "table" then --converts text to string if it's a table
    text = table.concat(text,"[\n]")
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
  local function endExecution(event)
    --closes input box and returns event and the values in the input fields
    local tRes = {}
    for iR=1,#tInputs do
      tRes[tInputs[iR].name] = tonumber(tInputs[iR].value) or tInputs[iR].value
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
    screen:delLayer(screen.layers.dialog)
    return event,tRes,reInput
  end
  --render box
  local buttonTouchMap,inputTouchMap
  if tTerm.color then
    local box = {
      height = #tLine+2+#tInputs,
      width = tTerm.screen.x-2
    }
    box.top = tTerm.screen.yMid-math.floor(box.height/2)
    box.bottom = tTerm.screen.yMid+math.ceil(box.height/2)
    screen:drawBox(2,box.top,tTerm.screen.x-1,box.bottom,tColors.inputBox)
    screen:drawFrame(1,box.top,tTerm.screen.x,box.bottom,tColors.inputBoxBorder)
    --write text
    screen:setBackgroundColor(tColors.inputBox)
    screen:setTextColor(tColors.inputBoxText)
    for i=1,#tLine do
      screen:setCursorPos(tTerm.screen.xMid-math.ceil(#tLine[i]/2),box.top+i)
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
    local nextButton = tTerm.screen.xMid-math.ceil(totalButtonSpace/2)+2
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
    screen:write(fieldString..string.rep(" ",math.max(0,field.lX-#fieldString)))
    screen:setCursorPos(field.sX+field.cX,field.y)
  end
  while true do
  --user interaction begins
    local tEvent = {os.pullEvent()}
    if customEvent then
      local button = customEvent(tEvent)
      if button then
        return endExecution(button)
      end
    end
    if tEvent[1] == "timer" then
      local timerID = tEvent[2]
      if timerID == tTimers.blink.id then
        local toggle = tTimers.blink.toggle
        tTimers.blink.toggle = not toggle
        if toggle then
          renderToolOverlay()
        else
          screen:delLayer(screen.layers.toolsOverlay)
        end
        tTimers.blink.id = os.startTimer(tTimers.blink.time)
      end
    elseif tEvent[1] == "mouse_click" then
      local x,y = tEvent[3],tEvent[4]
      if inputTouchMap[x][y] then --input bar clicked
        tInputs.enabled = inputTouchMap[x][y]
        local enabled = tInputs.enabled
        screen:setCursorPos(math.min(#tInputs[enabled].value+tInputs[enabled].sX,x),y)
        tInputs[enabled].cX = (screen:getCursorPos())-tInputs[enabled].sX
      elseif buttonTouchMap[x][y] then
        return endExecution(buttonTouchMap[x][y])
      end
    elseif tEvent[1] == "char" and tInputs.enabled then
      local field = tInputs[tInputs.enabled]
      if tEvent[2]:match(field.accepted) then -- check for accepted character
        field.value = field.value:sub(1,field.cX+field.scroll)..tEvent[2]..field.value:sub(field.cX+field.scroll+1)
        field.cX = field.cX+1
        refreshField(tInputs.enabled)
      end
    elseif tEvent[1] == "key" then
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
    end
  end
end

--[[----------------------------------------------------------------------------------------------------------
Turtle functions
----------------------------------------------------------------------------------------------------------]]--
function selectColor(color,threshold)
  --checks the slots assigned to (color) for blocks,
  --and acts accordingly
  threshold = threshold or 0 --min amount of items in accepted slot
  while true do
    for k,v in pairs(tColorSlots[color]) do
      if turtle.getItemCount(v) > threshold then
        turtle.select(v)
        return true
      end
    end
    if cTurtle.tSettings.enderChest then
      if cTurtle.enderRestock(cTurtle.tSettings.enderChest,tColorSlots[colorNum],tColorSlots[colorNum]) then
        turtle.select(tColorSlots[color][1])
        return true
      end
    end
    local retry = os.startTimer(tTimers.restockRetry)
    local button,tRes = input(
      color.." blocks required in slots "..tColorSlots[color][1].."-"..tColorSlots[color][#tColorSlots[color]],
      {
        "Cancel",
        "Ok"
      },
      false,
      function(tEvent)
        if tEvent[1] == "timer" and tEvent[2] == retry then
          return "Ok"
        end
      end
    )
    if button == "Cancel" then
      return false
    end
  end
end

function build(blueprint,sLayer,eLayer)
  --builds the given blueprint layers
  blueprint = blueprint or tBlueprint
  sLayer = sLayer or 1 --start layer
  eLayer = eLayer or #blueprint --end layer
  local tOrigin = {}--construction start point
  for k,v in pairs(cTurtle.tPos) do
    tOrigin[k] = v
  end
  for i = sLayer,eLayer do
    for kX,vX in pairs(blueprint[i]) do
      cTurtle.moveTo(kX,"X")
      for kZ,vZ in pairs(blueprint[i][k]) do
        cTurtle.moveTo(kZ,"Z")
        if not selectColor(v) then
          return
        end
        cTurtle.replace(buildDir)
      end
    end
    cTurtle.move"up"
  end
end

--[[----------------------------------------------------------------------------------------------------------
Other functions
----------------------------------------------------------------------------------------------------------]]--


--[[----------------------------------------------------------------------------------------------------------
Program execution begins
----------------------------------------------------------------------------------------------------------]]--
tBlueprint = tBlueprint.load(tArg[1] or "") or tBlueprint
tFile.blueprint = tBlueprint[1] and tArg[1]
--[[----------------------------------------------------------------------------------------------------------
Non-color program
----------------------------------------------------------------------------------------------------------]]--
if not tTerm.color then
  while true do
    local tEvent = {os.pullEvent()}
    if tEvent[1] == "key" then
      if tEvent[2] == 203 then
        
      elseif tEvent[2] == 205 then
        
      end
    end
  end
else
--[[----------------------------------------------------------------------------------------------------------
Color program
----------------------------------------------------------------------------------------------------------]]--
  tBlueprint[1] = tBlueprint[1] or class.layer:new()
  tTimers.blink.id = os.startTimer(tTimers.blink.time)
  tTimers.blink.toggle = true
  renderBottomBar()
  renderSideBar()
  tBlueprint[1]:render()
  while true do
    local tEvent = {os.pullEvent()}
    if tEvent[1] == "timer" then
      local timerID = tEvent[2]
      if timerID == tTimers.blink.id then
        local toggle = tTimers.blink.toggle
        tTimers.blink.toggle = not toggle
        if toggle then
          renderToolOverlay()
        else
          screen:delLayer(screen.layers.toolsOverlay)
        end
        tTimers.blink.id = os.startTimer(tTimers.blink.time)
      end
    elseif tEvent[1] == "mouse_click"
    or tEvent[1] == "mouse_drag" then
      local button,x,y = tEvent[2],tEvent[3],tEvent[4]
      if tBar.touchMap[x][y] and tEvent[1] == "mouse_click" then --right menu bar click
        tBar.touchMap[x][y](button)
      elseif tMenu.open and tMenu.touchMap[x][y] then
        if tMenu.touchMap[x][y] ~= true then --true signifies a disabled menu
          tMenu.touchMap[x][y](button)
        end
      elseif y <= tTerm.canvas.eZ
      and y >= tTerm.canvas.sZ 
      and x <= tTerm.canvas.eX
      and x >= tTerm.canvas.sX then --canvas click
        x,y = x-tTerm.viewable.mX,y-tTerm.viewable.mZ
        if tMenu.open then
          renderMenu() --closes open menu
        elseif tMenu.rightClick.open then
          scroll()
          renderBottomBar()
          renderSideBar()
        elseif button ~= 3 then
          --executes tool function
          local tool = tTool[button].tool
          local color = tTool[button].color
          tTool[tool](tEvent[1],button,x,y,color,tTerm.scroll.layer)
        end
      end
    elseif tEvent[1] == "key" then
      if tEvent[2] == 203 then --left arrow
        scroll(false,-1,0)
      elseif tEvent[2] == 205 then --right arrow
        scroll(false,1,0)
      elseif tEvent[2] == 208 then --down arrow
        scroll(false,0,1)
      elseif tEvent[2] == 200 then --up arrow
        scroll(false,0,-1)
      end
    elseif tEvent[1] == "mouse_scroll" then
      scroll(false,0,tEvent[2])
    end
  end
end