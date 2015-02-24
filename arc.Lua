--[[
--------------------------------------------------------------------------------------------------------------
|                                              Turtle Architect                                              |
|                                                by CometWolf                                                |
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------
environment init
----------------------------------------------------------------------------------------------------------]]--
if multishell then --disable multishell for performance reasons
  term.redirect(term.native())
end

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
tFile.APIFolder = tFile.folder.."/APIs" --APIs folder
tFile.functionFolder = tFile.folder.."/Functions" --Functions folder
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
Load class files and APIs
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
  local func = setfenv(tRes[1],env or progEnv)
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

--load APIs
for _k,file in pairs(fs.list(tFile.APIFolder)) do
  if not file:match"glasses" and not file:match"window" then --glasses and window API must be loaded after the settings, which is done after assorted variables are defined.
    loadFile(tFile.APIFolder.."/"..file,progEnv)
  end
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
loadFile(tFile.APIFolder.."/glasses.lua")
loadFile(tFile.APIFolder.."/window.lua")

--[[----------------------------------------------------------------------------------------------------------
Program init
----------------------------------------------------------------------------------------------------------]]--

if turtle then
  if not term.isColor() then
    error("Turtle Architect is incompatible with regular turtles!",0)
  end
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

--load program functions
for _k,file in pairs(fs.list(tFile.functionFolder)) do
  loadFile(tFile.functionFolder.."/"..file,progEnv)
end
--[[----------------------------------------------------------------------------------------------------------
Event handlers
----------------------------------------------------------------------------------------------------------]]--
eventHandler = loadFile(tFile.eventHandlerFolder.."/eventHandler.Lua")
local execution = function()
  while rawget(screen,1) do --clear buffer for redraw, incase of crash
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