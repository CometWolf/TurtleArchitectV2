local main
main = { 
  mouse_click = function(tEvent)
    local button,x,y = tEvent[2],tEvent[3],tEvent[4]
    if tBar.touchMap[x][y] and tEvent[1] == "mouse_click" then --right menu bar click
      tBar.touchMap[x][y](button)
    elseif tMenu.open and tMenu.touchMap[x][y] then
      if tMenu.touchMap[x][y] ~= true then --true signifies a disabled menu
        tMenu.touchMap[x][y](button)
      end
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
      elseif button ~= 3 then
        --executes tool function
        local tool = tTool[button].tool
        local color = tTool[button].color
        tTool[tool](tEvent[1],button,x,y,color,tTerm.scroll.layer)
      end
    end
  end,
  key = function(tEvent)
    local key = tEvent[2]
    if tTimers.ctrl.pressed then
      if key == 48 then --B
        local tool = tTool[1]
        if tool.tool == "Brush" then
          tool.tool = tool.prevTool or tool.tool
        else
          tool.prevTool = tool.tool
          tool.tool = "Brush"
        end
        renderBottomBar()
      end
    elseif key == 203 then --left arrow
      scroll(false,-1,0)
    elseif key == 205 then --right arrow
      scroll(false,1,0)
    elseif key == 208 then --down arrow
      scroll(false,0,1)
    elseif key == 200 then --up arrow
      scroll(false,0,-1)
    elseif key == 209 then --page down
      scroll(tTerm.scroll.layer-1)
    elseif key == 201 then --page up
      scroll(tTerm.scroll.layer+1)
    elseif key == 29 then --ctrl
      tTimers.ctrl.pressed = true
      tTimers.ctrl.start()
    end
  end,
  mouse_scroll = function(tEvent)
    scroll(false,0,tEvent[2])
  end
}
main.mouse_drag = main.mouse_click
return main