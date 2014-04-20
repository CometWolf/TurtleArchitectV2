local tool = {
  menuOrder = 1, --menu order, 1 being top
  selectFunc = function(button)
    tTool.change("Brush",button)
  end,
  renderFunc = function(event,button,x,z,color)
    drawPoint(x,z,color)
    sync(
      {
        layer = tTerm.scroll.layer,
        x = x+tTerm.scroll.x,
        z = z+tTerm.scroll.z,
        color = color
      },
      "Point"
    )
  end
}
return tool