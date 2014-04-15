
local tool = {
  menuOrder = 2, --menu order, 1 being top
  selectFunc = function(button)
    tTool.change("hSquare",button)
  end,
  renderFunc = function(event,button,x,z,color,layer)
    drawPoint(x,z,color)
  end
}
return tool