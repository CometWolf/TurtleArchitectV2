modemChannel = 62700 --Channel used to communicate with other computers/turtles running Turtle Architect

tColors = setmetatable(
  { -- color settings
    canvas = colors.white, --changing this can cause some derps
    bottomBar = colors.gray, --Bottom bar color
    coordsText = colors.white, --text color for the coordinates on the bottom right
    sideBarText = colors.white, --menu buttons text color
    sideBar = colors.gray, --menu sidebar color
    menuTop = colors.blue, --menu header color
    menuPri = colors.black, --Menu color alteration primary 
    menuSec = colors.gray, --Menu color alteration secondary
    enabledMenuText = colors.yellow, --Enabled Menus text
    disabledMenuText = colors.lightGray, --disabled menus text
    inputBox = colors.gray, -- popup boxes background
    inputBoxBorder = colors.lightGray, --popup boxes border
    inputBoxText = colors.yellow, --popup boxes text
    inputBar = colors.black, --popup boxes input fields
    inputText = colors.white, --popup boxes input fields text
    inputButton = colors.lightBlue, --popup boxes buttons
    inputButtonText = colors.yellow, --popup boxes buttons text
    scrollBoxSelectText = colors.white, --popup scroll boxes scroll selection text
    scrollBoxSelected = colors.blue, --popup scroll boxes selected scroll selection background
    scrollBoxUnselected = colors.black, --popup scroll boxes selected scroll selection background
    builtMarker = colors.white, --built mode marker
    gridMarkerMajor = colors.blue, --grid mode marker for major units
	  gridMarkerMinor = colors.lightBlue, --grid mode marker for minor units
    gridMarkerMajor2 = colors.black, --this is used when rendering the grid ontop of a block matching the color of gridMarkerMajor
    gridMarkerMinor2 = colors.gray, --this is used when rendering the grid ontop of a block matching the color of gridMarkerMinor
    gridBorder = colors.blue, -- background for grid numbers
    gridBorderText = colors.white, --grid numbers 12345...
    backgroundLayer = colors.gray, --background layer rendered with background mode
    toolText = colors.white, --T1 and T2 on the bottom bar, this color is also used as the background if the tool currently has the same color as the bottom bar equipped
    rightClickPri = colors.black, --Right click selection menu color alteration primary
    rightClickSec = colors.gray, --Right click selection menu color alteration secondary
    rightClickUseable = colors.white, --Useable right click selection menu options
    rightClickUnuseable = colors.lightGray, --Not useable right click selection menu options
    selection = colors.gray, --Color of the selection marker
    layerBar = colors.black, --Background color of the layer bar
    layerBarViewSelected = colors.lightBlue, --in view and selected layer item on the layer bar
    layerBarViewUnselected = colors.lightGray, --in view layer item on layer bar    
    layerBarSelected = colors.blue, --Selected layer item on the layer bar
    layerBarUnselected = colors.black, --Unselected layer item on the layer bar
    layerBarText = colors.white, --layer numbers color on the layer bar
  },
  {
    __index = function(t,k)
      error("The color "..k.." is not defined!",2)
    end
  }
)
tColors.glass = { --glass colors
	white = 0xFFFFFF,
	orange = 0xFFA500,
	magenta = 0xFF00FF,
	lightBlue = 0xADD8E6,
	yellow = 0xFFFF00,
	lime = 0x00FF00,
	pink = 0xFFC0CB,
	gray = 0x808080,
	lightGray = 0xD3D3D3,
	cyan = 0x00FFFF,
	purple = 0x800080,
	blue = 0x0000FF,
	brown = 0xA52A2A,
	green = 0x008000,
	red = 0xFF0000,
	black = 0x000000,
}
glasses = { --openP glass settings
  screen = {
    size = { --the size of each screen pixel
      x = 3,
      y = 5 
    },
    pos = { --where to render the glasses screen
      x = 0,
      y = 0
    },
    opacity = 1 --screen transparency
  },
  log = { --where to render the message bar
    sX = 331,
    sY = 100,
    eX = 480,
    eY = 246,
    opacity = 0.5, --log transparency
	  maxSize = 50, --amount of entries to store in the log
    timers = {--used to store cleanup timer functions, indexed by timer id
      
    }
  },
  followTurtle = true, --whether to auto scroll the canvas along with the turtle as it builds, provided you have glasses connected
  screenMode = "Screen Log", --glasses display mode,simply write which modes you want in plain text, remember to capitalize the first letter
  colors = {} --CC to HEX color conversion
}
--cc to hex color conversion table
local colorValueToHex = {}
for gK,gV in pairs(tColors.glass) do
  for cK,cV in pairs(colors) do
    if gK == cK then
      colorValueToHex[cV] = gV
      break
    end
  end
end
for k,v in pairs(colorValueToHex) do
  glasses.colors[k] = v
end
tColors.glass.log = tColors.glass.blue --message log window color
tColors.glass.logText = tColors.glass.yellow --message log text color

tTimers = setmetatable( -- timer settings
  {
    restockRetry = { --wait before re-attempting failed restock
      time = 20,
    },
    blink = { --how often to blink tool overlays
      time = 1
    },
    modemRes = { --how long to wait for a modem response
      time = 3,
    },
    connectionPing = { --How often to check connection
      time = 10,
    },
    inputTimeout = { --Time to wait for time sensitive dialogue boxes, eg accept blueprint transmission or sync mode
      time = 100
    },
    shift = { --shift key press timer, for shift shortcuts
      time = 1
    },
    ctrl = { --ctrl key press timer, for ctrl shortcuts
      time = 1
    },
    display = { --time a openP glasses message remains in the log
      time = 20
    },
    scan = { --time to wait for responses when scanning for other computers running TA
      time = 1
    }
  },
  {
    __index = function(t,k)
      error("The timer "..k.." is not defined!",2)
    end
  }
)
for k,v in pairs(tTimers) do
  v.ids = {}
  v.start = function(time)
    v.id = os.startTimer(time or v.time)
    v.ids[v.id] = true
    return v.id
  end
  v.stop = function()
    v.id = nil
  end
end

colorKey = setmetatable(
  { --what character correlates to what color in the blueprint
    [" "] = tColors.canvas,
    a = 2 ^ 1, --orange
    b = 2 ^ 2, --purple
    c = 2 ^ 3, --light blue
    d = 2 ^ 4, --yellow
    e = 2 ^ 5, --lime
    f = 2 ^ 6, --pink
    g = 2 ^ 7, --gray
    h = 2 ^ 8, --light gray
    i = 2 ^ 9, --blue
    j = 2 ^ 10, --purple
    k = 2 ^ 11, --blue
    l = 2 ^ 12, --brown
    m = 2 ^ 13, --green
    n = 2 ^ 14, --red
    o = 2 ^ 15  --black
  },
  {
    __index = function(t,k)
      error("Attempt to access non-existant color "..(tostring(k) or "nil"),2)
    end
  }
)

local colorLoop = {}
keyColor = {}
for kK,vK in pairs(colorKey) do -- add color names to colorKey table
  colorLoop[kK:upper()] = vK
  for kC,vC in pairs(colors) do
    if vC == vK then
      colorLoop[vC] = kK
      colorLoop[kC] = kK
      kC = kC:gsub("(%u)",function(l) return " "..l:lower() end)
      keyColor[kK] = kC:sub(1,1):upper()..kC:sub(2)
      keyColor[kK:upper()] = keyColor[kK]
      break
    end
  end
end
for k,v in pairs(colorLoop) do
  colorKey[k] = v
end
colorLoop = nil

paintColors = { --paint colors,used for conversion
  j = "a",
  k = "b",
  l = "c",
  m = "d",
  n = "e",
  o = "f",
  X = "e"
}
for i=1,9 do
  paintColors[colorKey[2^i]] = i
end
local paintUpper = {}
for k,v in pairs(paintColors) do
  paintUpper[k:upper()] = v
end
for k,v in pairs(paintUpper) do
  paintColors[k] = v
end
paintUpper = nil

keyColor.S = "Scan"
colorKey.S = colors.blue
keyColor.X = "Break"
colorKey.X = colors.red --break block marker

local shortcutChange = function(t1,t2,primary) --ctrl shortcut tool change function
  local secondary = primary == 1 and 2 or 1
  if t1 == tTool[primary].tool then
    if tTool[primary].prevDouble then
      tTool.change(tTool[primary].prevTool,primary,secondary)
    elseif tTool[primary].double and tTool[secondary].double then
      tTool.change(tTool[primary].prevTool,primary)
      tTool.change(tTool[secondary].prevTool,secondary)
      tTool[primary].prevDouble = true
      tTool[secondary].prevDouble = true
    else
      tTool.change(tTool[primary].prevTool or tTool[primary].tool,primary,t2 and secondary or nil)
    end
  elseif tTool[primary].double then
    if t2 or tTool[secondary].prevDouble then
      tTool.change(t1,primary,secondary)
    else
      tTool.change(t1,primary)
      tTool.change(tTool[secondary].prevTool,secondary)
    end
  else
    tTool.change(t1,primary,t2 and secondary or nil)
  end
end

ctrlShortcuts = { --ctrl+key shortcuts, left ctrl button = 1, right ctrl button = 2
  default = { --these are active by default
    [48] = function(button) --B
      shortcutChange("Brush",nil,button)
    end,
    [33] = function(button) --F
      shortcutChange("Fill",nil,button)
    end,
    [25] = function(button) --P
      shortcutChange("Pipette",nil,button)
    end,
    [31] = function(button) --S
      if tTool[1].tool == "Select" then
        shortcutChange("Select",true,button)
      else
        tTool.selected.Select()
      end
    end,
    [46] = function(button) --C
      shortcutChange("Code",nil,button)
    end,
    [38] = function(button) --L
      shortcutChange("Line",true,button)
    end,
    [32] = function(button) --D
      shortcutChange("Drag",nil,button)
    end,
    [49] = function() --N
      table.insert(tBlueprint,tTerm.scroll.layer+1,class.layer.new())
      scroll(tTerm.scroll.layer+1)
    end,
    [35] = function() --H
      toggleMenus()
    end,
  },
  active = { --holds the currently active shortcuts, don't add anything here
    
  }
}
for k,v in pairs(ctrlShortcuts.default) do --activate default shortcuts
  ctrlShortcuts.active[k] = v
end

tTool = { --Default equipped tools and colors
  [1] = { --left mouse button
    tool = "Brush",
    color = colorKey.black
  },
  [2] = { --right mouse button
    tool = "Brush",
    color = colorKey.white
  },
  [3] = { --middle mouse button, somewhat secret...
    tool = "Help",
    color = colorKey.white
  },
  select = {}, --contains selection tool info
  clipboard = false, --tool clipboard
  shape = {}, --contains circle and square tool info
  selected = {}, --contains select functions, indexed by tool name
  deselected = {}, --contains deselect functions, indexed by tool name
}

tMode = { -- default modes
  builtDraw = false,
  builtRender = true,
  overwrite = true,
  grid = false,
  gridMajor = 10,
  layerBar = true,
  backgroundLayer = false,
  hideMenus = false,
  sync = {
    amount = 0,
    turtles = 0,
    ids = {
    
    }
  }
}