
local tool 
tool = {
  menuOrder = 7, --menu order, 1 being top
  selectFunc = function(button)
    tTool.change("Select",1,2)
  end,
  renderFunc = function(event,button,x,z,color)
    if button == 1 then
      screen:setLayer(screen.layers.toolsOverlay)
      local c = tTool.clipboard
      local t = tTool.select
      if c then
        c.sX = x+tTerm.scroll.x
        c.sZ = z+tTerm.scroll.z
        c.eX = c.sX+c.lX-1
        c.eZ = c.sZ+c.lZ-1
      elseif event == "mouse_click" then
        t.sX = x+tTerm.scroll.x
        t.sZ = z+tTerm.scroll.z
        t.eX = nil
        t.eZ = nil
      else --drag
        t.eX = x+tTerm.scroll.x
        t.eZ = z+tTerm.scroll.z
      end
      renderToolOverlay()
      tTimers.blink.id = os.startTimer(tTimers.blink.time)
    else --right click
      tMenu.rightClick.render(x,z)
    end
  end
}
return tool