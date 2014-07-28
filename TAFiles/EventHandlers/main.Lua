local toolChange = function(t1,t2,primary)
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
        tTool[tool](tEvent[1],button,x,y,color,tTerm.scroll.layer)
      end
      return true
    end
  end,
  key = function(tEvent)
    local key = tEvent[2]
    if key == 203 then --left arrow
      scroll(false,-1,0)
      return true
    elseif key == 205 then --right arrow
      scroll(false,1,0)
      return true
    elseif key == 208 then --down arrow
      scroll(false,0,1)
      return true
    elseif key == 200 then --up arrow
      scroll(false,0,-1)
      return true
    elseif key == 209 then --page down
      scroll(tTerm.scroll.layer-1)
      return true
    elseif key == 201 then --page up
      scroll(tTerm.scroll.layer+1)
      return true
    elseif key == 87 -- F11
      toggleMenus()
    elseif key == 42
    or key == 54 then --shift
      if not tTimers.shift.pressed then
        tTimers.shift.pressed = true
        tTimers.shift.start()
        return true
      end
    elseif key == 29 then --left ctrl
      if not tTimers.ctrl.lPressed then
        tTimers.ctrl.lPressed = true
        tTimers.ctrl.start()
        return true
      end
    elseif tTimers.ctrl.lPressed then
      local tool = tTool.shortcuts[key]
      if tool then
        toolChange(tool[1],tool[2],1)
        return true
      end
    elseif key == 157 then --right ctrl
      if not tTimers.ctrl.rPressed then
        tTimers.ctrl.rPressed = true
        tTimers.ctrl.start()
        return true
      end
    elseif tTimers.ctrl.rPressed then
      local tool = tTool.shortcuts[key]
      if tool then
        toolChange(tool[1],tool[2],2)
        return true
      end
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