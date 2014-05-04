local tool
tool = {
  menuOrder = 1, --menu order, 1 being top
  selectFunc = function(button)
    tTool.change("Brush",button)
  end,
  renderFunc = function(event,button,x,z,color,layer)
    drawPoint(x,z,color,layer)
    sync(
      {
        layer = tTerm.scroll.layer,
        x = x+tTerm.scroll.x,
        z = z+tTerm.scroll.z,
        color = color
      },
      "Point"
    )
  end,
  codeFunc = function(x,z,color,layer)
    if not (type(x) == "number" and type(z) == "number") then
      error("Expected number,number",2)
    end
    color = color or codeEnv.color
    layer = layer or codeEnv.layer
    if codeEnv.settings.direct then
      drawPoint(x,z,color,layer,true)
    else
      codeEnv.blueprint[layer]:paste(calcFunc(sX,sZ,eX,eZ,color),math.min(sX,eX),math.min(sZ,eZ),not tMode.overwrite)
    end
  end
}
return tool