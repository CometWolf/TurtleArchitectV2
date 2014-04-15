local tool = {
  menuOrder = 1, --menu order, 1 being top
  selectFunc = function(button)
    tTool.change("Brush",button)
  end,
  renderFunc = function(event,button,x,z,color)
    drawPoint(x,z,color)
  end
}
return tool