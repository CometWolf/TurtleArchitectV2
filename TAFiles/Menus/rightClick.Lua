local rightClick = {}

for _k,file in pairs(fs.list(tFile.menuFolder.."/rightClick")) do
  if not fs.isDir(tFile.menuFolder.."/"..file) then
    rightClick[file:match"(.+)%.Lua"] = loadFile(tFile.menuFolder.."/rightClick/"..file,progEnv)
  end
end

--create menu strings
for name,menu in pairs(rightClick) do
  menu.name = name
  local longest = 0
  for i,menu in ipairs(menu) do
    longest = math.max(longest,#menu.name)
  end
  menu.lX = longest+1
  longest = longest/2 --center text
  for i,menu in ipairs(menu) do
    local name = menu.name
    menu.string = string.rep(" ",math.floor(longest+1-(#name/2)))..name..string.rep(" ",math.ceil(longest+1-(#name/2)))
  end
  menu.lZ = #menu
end

rightClick.render = function(menu,x,z)
  menu = rightClick[menu]
  if not menu then
    return
  end
  screen:setLayer(screen.layers.menus)
  x = x or menu.sX
  z = z or menu.sZ
  menu.eZ = z+menu.lZ
  menu.eX = x+menu.lX
  tMenu.touchMap = class.matrix.new(2)
  tMenu.open = menu.name
  local eX = x+menu.lX
  local eZ = z+menu.lZ
  while eX > tTerm.canvas.eX do
    eX = eX-1
    x = x-1
  end
  while eZ > tTerm.canvas.eZ+1 do
    eZ = eZ-1
    z = z-1
  end
  menu.sX = x
  menu.sZ = z
  menu.splits = math.ceil(menu.lX/tTerm.screen.y-1)
  if menu.splits <= 1 then
    while menu.sZ < 1 do
      menu.sZ = menu.sY+1
      menu.eZ = menu.eY+1
    end
    while menu.eZ > tTerm.screen.y do
      menu.sZ = menu.sY-1
      menu.eZ = menu.eY-1
    end
  else
    menu.sZ = 1
    menu.eZ = math.ceil(menu.lY/menu.splits)
    menu.lZ = menu.lZ
    menu.sX = menu.sX-(menu.lX*(menu.splits-1))
  end
  for i,item in ipairs(menu) do
    local z = z+i-1
    screen:setCursorPos(x,z)
    screen:setBackgroundColor((i%2 == 0 and tColors.rightClickPri) or tColors.rightClickSec)
    local help = item.help
    local helpFunc = (
      help
      and function(button)
        return tTool[button].tool == "Help" and (help() or true)
      end
      or function(button)
        return tTool[button].tool == "Help" and window.text(menu[i].name.."\ndosen't have a help function. Please define it in the menu file as \"help\"") and true
      end
    )
    if type(item.enabled) == "function" and item.enabled() or item.enabled == true then
      screen:setTextColor(tColors.rightClickUseable)
      local function menuFunc(button)
        if not helpFunc(button) then
          renderMenu()
          item.func(button)
        end
      end
      for iX = x,eX do
        tMenu.touchMap[iX][z] = menuFunc
      end
    else
      screen:setTextColor(tColors.rightClickUnuseable)
      for iX = x,eX do
        tMenu.touchMap[iX][z] = helpFunc
      end
    end
    screen:write(item.string)
  end
end

return rightClick