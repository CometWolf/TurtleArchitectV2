local tool
tool = {
  menuOrder = 11, --menu order, 1 being top
  enabled = true,
  help = function(clickButton)
    local button = window.text(
      "The drag tool lets you drag the view around, instead of having to use the arrow keys or mouse wheel",
      {
        "Ok",
        "Equip"
      }
    )
    if button == "Equip" then
      tool.selectFunc(clickButton)
    end
  end,
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