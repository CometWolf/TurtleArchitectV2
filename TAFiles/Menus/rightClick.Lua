local menu
menu = {
  [1] = {
    name = "Cut",
    select = true,
    func = function()
      local t = tTool.select
      tTool.clipboard = tBlueprint[tTerm.scroll.layer]:copy(t.sX,t.sZ,t.eX,t.eZ,true)
      for iX = math.min(t.sX,t.eX),math.max(t.eX,t.sX) do
        for iZ = math.min(t.sZ,t.eZ),math.max(t.eZ,t.sZ) do
          drawPoint(iX,iZ," ")
        end
      end
      tTool.select = {}
    end
  },
  [2] = {
    name = "Copy",
    select = true,
    func = function()
      local t = tTool.select
      tTool.clipboard = tBlueprint[tTerm.scroll.layer]:copy(t.sX,t.sZ,t.eX,t.eZ,true)
      tTool.select = {}
      screen:delLayer(screen.layers.toolsOverlay)
      local c = tTool.clipboard
      c.sX = c.sX+1
      c.sZ = c.sZ+1
      c.eX = c.eX+1
      c.eZ = c.eZ+1
      renderToolOverlay()
    end
  },
  [3] = {
    name = "Paste",
    clipboard = true,
    func = function()
      local c = tTool.clipboard
      tBlueprint[tTerm.scroll.layer]:paste(c.l,c.sX-1,c.sZ-1)
      renderArea(c.sX,c.sZ,c.eX,c.eZ,true)
      c.sX = c.sX+1
      c.sZ = c.sZ+1
      c.eX = c.eX+1
      c.eZ = c.eZ+1
      renderToolOverlay()
    end
  },
  [4] = {
    name = "Recolor",
    select = true,
    clipboard = true,
    func = function(button)
      local c = tTool.clipboard
      local color = tTool[button].color
      if c then
        c.l:recolor(color,1,1,c.lX,c.lZ)
        renderToolOverlay()
      else
        local t = tTool.select
        local layer = tBlueprint[tTerm.scroll.layer]
        layer:recolor(color,t.sX,t.sZ,t.eX,t.eZ)
        renderArea(t.sX,t.sZ,t.eX,t.eZ,true)
      end
    end
  },
  [5] = {
    name = "Flip vert",
    select = true,
    clipboard = true,
    func = function()
      local t = tTool.select
      local c = tTool.clipboard
      local layer = tBlueprint[tTerm.scroll.layer]
      if t.eX then
        local flip = layer:copy(t.sX,t.sZ,t.eX,t.eZ,true):flipZ(t.sX,t.sZ,t.eX,t.eZ)
        layer:paste(flip,t.sX,t.sZ)
        renderArea(t.sX,t.sZ,t.eX,t.eZ,true)
      else
        c.l = c.l:flipZ(1,1,c.lX,c.lZ)
        renderToolOverlay()
      end
    end
  },
  [6] = {
    name = "Flip hori",
    select = true,
    clipboard = true,
    func = function()
      local t = tTool.select
      local c = tTool.clipboard
      local layer = tBlueprint[tTerm.scroll.layer]
      if t.eX then
        local flip = layer:copy(t.sX,t.sZ,t.eX,t.eZ,true):flipX(t.sX,t.sZ,t.eX,t.eZ)
        layer:paste(flip,t.sX,t.sZ)
        renderArea(t.sX,t.sZ,t.eX,t.eZ,true)
      else
        c.l = c.l:flipX(1,1,c.lX,c.lZ)
        renderToolOverlay()
      end
    end
  },
  [7] = {
    name = "Mark built",
    select = true,
    clipboard = true,
    func = function()
      local t = tTool.select
      local c = tTool.clipboard
      if t.eX then
        tBlueprint[tTerm.scroll.layer]:markBuilt(t.sX,t.sZ,t.eX,t.eZ)
        if tMode.renderBuilt then
          renderArea(t.sX,t.sZ,t.eX,t.eZ,true)
        end
      else
        c.l:markBuilt(1,1,c.lX,c.lZ)
        renderToolOverlay()
      end
    end
  },
  [8] = {
    name = "Mark unbuilt",
    select = true,
    clipboard = true,
    func = function()
      local t = tTool.select
      local c = tTool.clipboard
      if t.eX then
        tBlueprint[tTerm.scroll.layer]:markUnbuilt(t.sX,t.sZ,t.eX,t.eZ)
      else
        c.l:markUnbuilt(1,1,c.lX,c.lZ)
        renderToolOverlay()
      end
    end
  },
  [9] = {
    name = "Delete",
    select = true,
    clipboard = true,
    func = function()
      local t = tTool.select
      local c = tTool.clipboard
      if t.eX then
        for iX = math.min(t.sX,t.eX),math.max(t.eX,t.sX) do
          for iZ = math.min(t.sZ,t.eZ),math.max(t.eZ,t.sZ) do
            drawPoint(iX,iZ," ")
          end
        end
      else
        tTool.clipboard = false
        screen:delLayer(screen.layers.toolsOverlay)
      end
    end
  },
  render = function(x,z)
    screen:setLayer(screen.layers.menus)
    x = x or menu.sX
    z = z or menu.sZ
    tMenu.touchMap = class.matrix.new(2)
    tMenu.open = "rightClick"
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
    for i=1,#menu do
      local z = z+i-1
      screen:setCursorPos(x,z)
      screen:setBackgroundColor((i%2 == 0 and tColors.rightClickPri) or tColors.rightClickSec)
      if menu[i].select and tTool.select.eX
      or menu[i].clipboard and tTool.clipboard
      or not (menu[i].clipboard or menu[i].select) then
        screen:setTextColor(tColors.rightClickUseable)
        for iX = x,eX do
          tMenu.touchMap[iX][z] = function(button)
            menu[i].func(button)
            renderMenu()
          end
        end
      else
        screen:setTextColor(tColors.rightClickUnuseable)
        for iX = x,eX do
          tMenu.touchMap[iX][z] = true
        end
      end
      screen:write(menu[i].string)
    end
  end
}

local longest = 0
for i = 1,#menu do
  longest = math.max(longest,#menu[i].name)
end
menu.lX = longest+1
longest = longest/2 --center text
for i = 1,#menu do
  local name = menu[i].name
  menu[i].string = string.rep(" ",math.floor(longest+1-(#name/2)))..name..string.rep(" ",math.ceil(longest+1-(#name/2)))
end
menu.lZ = #menu

return menu