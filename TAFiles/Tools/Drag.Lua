local tool = {
  menuOrder = 8, --menu order, 1 being top
  selectFunc = function(button)
    tTool.change("Drag",button)
  end,
  renderFunc = function(event,button,x,z,color)
    if event == "mouse_click" then
      tTool.dragPoint = {
        x = x,
        z = z
      }
    else --mouse drag
      scroll(false,tTool.dragPoint.x-x,tTool.dragPoint.z-z)
      tTool.dragPoint = {
        x = x,
        z = z
      }
    end
  end
}
return tool