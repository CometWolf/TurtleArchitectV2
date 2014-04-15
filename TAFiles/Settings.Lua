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
    menuText = colors.yellow, --Menu text
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
      time = 20
    },
    blink = { --how often to blink clipboard contents and selection marker
      time = 1
    }
  },
  {
    __index = function(t,k)
      error("The timer "..k.." is not defined!")
    end
  }
)

colorKey = setmetatable(
  { --what character correlates to what color in the blueprint
    [" "] = tColors.canvasColor,
    a = 2 ^ 1,
    b = 2 ^ 2,
    c = 2 ^ 3,
    d = 2 ^ 4,
    e = 2 ^ 5,
    f = 2 ^ 6,
    g = 2 ^ 7,
    h = 2 ^ 8,
    i = 2 ^ 9,
    j = 2 ^ 10,
    k = 2 ^ 11,
    l = 2 ^ 12,
    m = 2 ^ 13,
    n = 2 ^ 14,
    o = 2 ^ 15,  --black
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
for kK,vK in pairs(colorKey) do -- add color names to colorKey to colorKey table
  colorKeyUpper[kK:upper()] = vK
  for kC,vC in pairs(colors) do
    if vC == vK then
    colorKeyNames[kC] = kK
      break
    end
  end
end

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
  builtRender = false,
  overwrite = true,
  grid = false,
  backgroundLayer = false,
  overwrite = true
}