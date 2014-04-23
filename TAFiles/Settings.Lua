modemChannel = 62700 --Channel used to communicate with other computers/turtles running Turtle Architect

tColors = setmetatable(
  { -- color settings
    canvasColor = colors.white, --changing this can cause some derps
    bottomBar = colors.gray,
    coordsText = colors.white,
    sideBarText = colors.white, --menu buttons text color
    sideBar = colors.gray,
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
    builtMarker = colors.white, --built mode marker
    gridMarker = colors.blue, --grid mode marker
    gridMarker2 = colors.white, --this is used when rendering the grid ontop of a block matching the color of gridMarker
    gridBorder = colors.blue, -- background for grid numbers
    gridBorderText = colors.white, --grid numbers 12345...
    backgroundLayer = colors.gray, --background layer rendered with background mode
    toolText = colors.white, --T1 and T2 on the bottom bar, this color is also used as the background if the tool currently has the same color as the bottom bar equipped
    rightClickPri = colors.black, --Right click selection menu color alteration primary
    rightClickSec = colors.gray, --Right click selection menu color alteration secondary
    rightClickUseable = colors.white, --Useable right click selection menu options
    rightClickUnuseable = colors.lightGray, --Not useable right click selection menu options
    selection = colors.gray, --Color of the selection marker
  },
  {
    __index = function(t,k)
      error("The color "..k.." is not defined!")
    end
  }
)
tTimers = setmetatable( -- timer settings
  {
    restockRetry = { --wait before re-attempting failed restock
      time = 20,
    },
    blink = { --how often to tool overlays
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
    [" "] = tColors.canvasColor,
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
    o = 2 ^ 15,  --black
    X = colors.red --break block marker
  },
  {
    __index = function(t,k)
      debug(k)
      error("Attempt to access non-existant color "..tostring(k),2)
    end
  }
)
local colorKeyNames = {}
local colorKeyUpper = {}
keyColor = {}
for kK,vK in pairs(colorKey) do -- add color names to colorKey table
  colorKeyUpper[kK:upper()] = vK
  for kC,vC in pairs(colors) do
    if vC == vK then
      colorKeyNames[kC] = kK
      keyColor[kK] = kC:gsub( --capitalize first letter, add space between first and second word and decap second word
        "^(.).-%l(%u)",
        function(l)
          return (
            l:match"%u" 
            and l:match " "..l:lower()
          ) or (
            l:upper()
          )
        end
      )
      break
    end
  end
end
keyColor.X = "Break"

for k,v in pairs(colorKeyNames) do
  colorKey[k] = v
end
colorKeyNames = nil

for k,v in pairs(colorKeyUpper) do
  colorKey[k] = v
end
colorKeyUpper = nil

tTool = { --Default equipped tools and colors
  [1] = { --left mouse button
    tool = "Brush",
    color = colorKey.black
  },
  [2] = { --right mouse button
    tool = "Brush",
    color = colorKey.white
  },
  select = {}, --contains selection tool info
  clipboard = false, --tool clipboard
  shape = {} --contains circle and square tool info
}

tMode = { -- default modes
  builtDraw = false,
  builtRender = true,
  overwrite = true,
  grid = false,
  backgroundLayer = false,
  sync = {
    amount = 0,
    turtles =0,
    ids = {
    
    }
  }
}