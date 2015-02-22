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
  menu.eZ = z+menu.lZ-1
  menu.eX = x+menu.lX
  tMenu.touchMap = class.matrix.new(2)
  tMenu.open = menu.name
  menu.sX = x
  menu.sZ = z
  menu.splits = math.ceil(menu.lZ/(tTerm.screen.y-1))
  if menu.splits > 1 then
    menu.sZ = 1
    menu.eZ = math.ceil(menu.lZ/menu.splits)
    menu.sX = tTerm.canvas.eX-(menu.lX*menu.splits)
    menu.eX = tTerm.canvas.eX
  else
    if menu.sZ < 1 then
      while menu.sZ < 1 do
        menu.sZ = menu.sZ+1
        menu.eZ = menu.eZ+1
      end
    elseif menu.eZ > tTerm.canvas.eZ then
      while menu.eZ > tTerm.canvas.eZ do
        menu.sZ = menu.sZ-1
        menu.eZ = menu.eZ-1
      end
    end
    if menu.sX < 1 then
      while menu.sX < 1 do
        menu.sX = menu.sX+1
        menu.eX = menu.eX+1
      end
    elseif menu.eX > tTerm.canvas.eX then
      while menu.eX > tTerm.canvas.eX do
        menu.sX = menu.sX-1
        menu.eX = menu.eX-1
      end
    end
  end
  local eZ = menu.eZ
  local nextMenu = 0
  for split=1,menu.splits do
    local sX = math.floor(menu.eX-(menu.lX*split))
    local eX = sX+menu.lX-split+1 --i dunno why this is necessary...
    for i=1,math.ceil(#menu/menu.splits) do
      nextMenu = nextMenu+1
      local item = menu[nextMenu]
      if not item then
        break
      end
      local help = item.help
      local helpFunc = (
        help
        and function(button)
          return tTool[button].tool == "Help" and (help() or true)
        end
        or function(button)
          return tTool[button].tool == "Help" and window.text(item.name.."\ndosen't have a help function. Please define it in the menu file as \"help\"") and true
        end
      )
      local iMenu = nextMenu
      local iZ = menu.sZ+i-1
      local enabled = item.enabled
      enabled = type(enabled) == "function" and enabled() or enabled == true
      screen:setBackgroundColor((i%2 == 0 and tColors.rightClickPri) or tColors.rightClickSec)
      if enabled then
        screen:setTextColor(tColors.rightClickUseable)
        local function menuFunc(button)
          if not helpFunc(button) then
            renderMenu()
            item.func(button)
          end
        end
        for iX = sX,eX do
          tMenu.touchMap[iX][iZ] = menuFunc
        end
      else
        screen:setTextColor(tColors.rightClickUnuseable)
        for iX = sX,eX do
          tMenu.touchMap[iX][iZ] = helpFunc
        end
      end
      screen:setCursorPos(sX,iZ)
      screen:write(item.string)
    end
  end
  --[[for i,item in ipairs(menu) do
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
  end]]
end

return rightClick
