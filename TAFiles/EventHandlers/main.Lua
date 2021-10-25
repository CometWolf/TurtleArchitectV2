local main
main = { 
  mouse_click = function(tEvent)
    local button,x,y = tEvent[2],tEvent[3],tEvent[4]
    if tMenu.open and tMenu.touchMap[x][y] then
      if tMenu.touchMap[x][y] ~= true then --true signifies a disabled menu
        tMenu.touchMap[x][y](button,x,y)
      end
      return true
    elseif tBar.touchMap[x][y] and tEvent[1] == "mouse_click" then --right menu bar click
      tBar.touchMap[x][y](button,x,y)
      return true
    elseif y <= tTerm.canvas.eZ
    and y >= tTerm.canvas.sZ 
    and x <= tTerm.canvas.eX
    and x >= tTerm.canvas.sX then --canvas click
      x,y = x-tTerm.viewable.mX,y-tTerm.viewable.mZ
      if tMenu.open then
        renderMenu() --closes open menu
      elseif tMenu.rightClick.open then
        renderBottomBar()
        renderSideBar()
      else
        --executes tool function
        local tool = tTool[button].tool
        local color = tTool[button].color
        tTool[tool](tEvent[1],button,x,y,tMode.builtDraw and color:upper() or color,tTerm.scroll.layer)
      end
      return true
    end
  end,
  key = function(tEvent)
    local key = tEvent[2]
    if key == keys.left then --left arrow
      scroll(false,-1,0)
      return true
    elseif key == keys.right then --right arrow
      scroll(false,1,0)
      return true
    elseif key == keys.down then --down arrow
      scroll(false,0,1)
      return true
    elseif key == keys.up then --up arrow
      scroll(false,0,-1)
      return true
    elseif key == keys.pageDown then --page down
      scroll(tTerm.scroll.layer-1)
      return true
    elseif key == keys.pageUp then --page up
      scroll(tTerm.scroll.layer+1)
      return true
    elseif key == keys["end"] then --end
      scroll(#tBlueprint)
      return true
    elseif key == keys.home then --home
      scroll(1)
      return true
    elseif key == keys.f11 then -- F11
      toggleMenus()
    elseif key == keys.leftShift
    or key == keys.rightShift then --shift
      if not tTimers.shift.pressed then
        tTimers.shift.pressed = true
        tTimers.shift.start()
        return true
      end
    elseif key == keys.leftCtrl then --left ctrl
      if not tTimers.ctrl.lPressed then
        tTimers.ctrl.lPressed = true
        tTimers.ctrl.start()
        return true
      end
    elseif tTimers.ctrl.lPressed and ctrlShortcuts.active[key] then
      ctrlShortcuts.active[key](1)
      return true
    elseif key == keys.rightCtrl then --right ctrl
      if not tTimers.ctrl.rPressed then
        tTimers.ctrl.rPressed = true
        tTimers.ctrl.start()
        return true
      end
    elseif tTimers.ctrl.rPressed and ctrlShortcuts.active[key] then
      ctrlShortcuts.active[key](2)
      return true
    end
  end,
  mouse_scroll = function(tEvent)
    local x,y = tEvent[3],tEvent[4]
    local layerBar = tBar.layerBar
    if x == layerBar.sX and tMode.layerBar and  y >= layerBar.sZ and y <= layerBar.eZ then
      local eLNew = layerBar.eL-tEvent[2]
      local sLNew = layerBar.sL-tEvent[2]
      if tBlueprint[eLNew]
      and tBlueprint[sLNew] then
        layerBar.eL = eLNew
        layerBar.sL = sLNew
        renderLayerBar()
      end
    else
      scroll(false,0,tEvent[2])
    end
    return true
  end
}
main.mouse_drag = main.mouse_click
return main
