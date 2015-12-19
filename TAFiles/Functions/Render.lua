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
    nextChar = (nextChar < 9 and nextChar+1 or 0)
  end
  screen:setCursorPos(1,2)
  nextChar = 1
  for i=2,canvas.eZ do
    screen:setCursorPos(1,i)
    screen:write(string.format(nextChar))
    nextChar = (nextChar < 9 and nextChar+1 or 0)
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
  tBlueprint[tTerm.scroll.layer]:render()
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
  if fullRefresh then
    screen:drawLine(layerBar.sX,layerBar.sZ,layerBar.eX,layerBar.eZ,tColors.layerBar)
    layerBar.eL = layerBar.eL-layerBar.sL+1
    layerBar.sL = 1
  end
  local indicatorLength = #string.format(layerBar.sL)
  for iX = 2,indicatorLength do
    tBar.touchMap[layerBar.eX-iX+1][layerBar.eZ] = layerBarClick
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
          if not tBlueprint[tTerm.scroll.layer+1] then
            tBlueprint[tTerm.scroll.layer+1] = class.layer.new()
            sync({layer = tTerm.scroll.layer+1},"Layer add")
          end
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
  local marker,bColor,tColor,gridColor,gridColor2
  local color = tBlueprint[tTerm.scroll.layer][x][z]
  local bgLayer = tMode.backgroundLayer
  if color == "X" then
    marker = "X"
    tColor = colorKey.X
    bColor = colors.white
  elseif color == "S" then
    marker = "S"
    tColor = colorKey.S
    bColor = colors.white
  elseif bgLayer and color == " " and (bgLayer[x][z] ~= " " and bgLayer[x][z] ~= "X") then
    if tMode.grid then
      marker = "+"
      if x%tMode.gridMajor == 0 or z%tMode.gridMajor == 0 then
        gridColor = tColors.gridMarkerMajor
        gridColor2 = tColors.gridMarkerMajor2
      else
        gridColor = tColors.gridMarkerMinor
        gridColor2 = tColors.gridMarkerMinor2
      end
      tColor = tColors.backgroundLayer ~= gridColor and gridColor or gridColor2
    end
    bColor = tColors.backgroundLayer
  elseif tMode.builtRender and color:match"%u" then
    marker = "B"
    tColor = tColors.builtMarker
  elseif tMode.grid then
    marker = "+"
    if x%tMode.gridMajor == 0 or z%tMode.gridMajor == 0 then
      gridColor = tColors.gridMarkerMajor
      gridColor2 = tColors.gridMarkerMajor2
    else
      gridColor = tColors.gridMarkerMinor
      gridColor2 = tColors.gridMarkerMinor2
    end
    tColor = colorKey[color] ~= gridColor and gridColor or gridColor2
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
