local tool = {
  menuOrder = 3, --menu order, 1 being top
  selectFunc = function(button)
    tTool.change("fSquare",button)
  end,
  renderFunc = function(event,button,x,z,color,layer)
    drawPoint(x,z,color)
  end
}
return tool