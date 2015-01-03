local tool
tool = {
  menuOrder = 1, --menu order, 1 being top
  enabled = true,
  help = function(clickButton)
    local button = window.text(
      "The brush tool is the simplest tool, it merely draws a single block of your chosen color",
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
    color = color or codeEnv.click.color
    layer = layer or codeEnv.click.layer
    local layerType = type(layer)
    if layerType == "table" and layer.paste then
      layer[x][z] = color
    elseif layerType == "number" then
      if codeEnv.settings.direct then
        drawPoint(x,z,color,layer,true)
      else
        codeEnv.blueprint[layer][x][z] = color
      end
    else
      error("Expected layer, got "..layerType,2)
    end
  end
}
return tool