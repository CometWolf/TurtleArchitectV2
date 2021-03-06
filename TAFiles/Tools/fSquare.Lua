local calcFunc = function(x1,z1,x2,z2,color)
  local x = {
    max = math.max(x1,x2),
    min = math.min(x1,x2)
  }
  x.max = x.max-x.min+1
  x.min = 1
  local z = {
    max = math.max(z1,z2),
    min = math.min(z1,z2)
  }
  z.max = z.max-z.min+1
  z.min = 1
  local points = class.layer.new()
  for iX = x.min,x.max do
    for iZ = z.min,z.max do
      points[iX][iZ] = color
    end
  end
  return points
end

local tool 
tool = {
  menuOrder = 5, --menu order, 1 being top
  enabled = true,
  help = function(clickButton)
    local button = window.text(
      "The filled square tool lets you draw a filled square by left clicking a point and dragging to the opposite point. When you are satisfied, simply right click to draw it on the blueprint",
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
    tTool.change("fSquare",1,2)
  end,
  renderFunc = function(event,button,x,z,color,layer)
    local s = tTool.shape
    if event == "mouse_click" then
      if button == 1 then
        s.sX = x+tTerm.scroll.x
        s.sZ = z+tTerm.scroll.z
        if s.eX then
          screen:clearLayer(screen.layers.toolsOverlay)
        end
        s.eX = false
        s.eZ = false
      elseif s.eX then --button 2
        s.layer = tTerm.scroll.layer
        sync(s,"Paste")
        tBlueprint[tTerm.scroll.layer]:paste(s.l,math.min(s.sX,s.eX),math.min(s.sZ,s.eZ),not tMode.overwrite)
        renderArea(s.sX,s.sZ,s.eX,s.eZ,true)
        tTool.shape = {}
        renderToolOverlay()
      end
    elseif button == 1 and s.sX then --drag
      s.eX = x+tTerm.scroll.x
      s.eZ = z+tTerm.scroll.z
      s.l = calcFunc(s.sX,s.sZ,s.eX,s.eZ,color)
      renderToolOverlay()
    end
  end,
  codeFunc = function(sX,sZ,eX,eZ,color,layer) --this is used by the code tool
    color = color or codeEnv.click.color
    layer = layer or codeEnv.click.layer
    if not (sX and sZ and eX and eZ)
    or not (type(sX) == "number" and type(sZ) == "number" and type(eX) == "number" and type(eZ) == "number") then
      error("Expected number,number,number,number",2)
    end
    if type(layer) == "table" and layer.paste then
      layer:paste(calcFunc(sX,sZ,eX,eZ,color),math.min(sX,eX),math.min(sZ,eZ),not tMode.overwrite)
    elseif codeEnv.settings.direct then
      local s = {
        sX = sX,
        sZ = sZ,
        eX = eX,
        eZ = eZ,
        layer = layer,
        l = calcFunc(sX,sZ,eX,eZ,color)
      }
      tBlueprint[layer]:paste(s.l,math.min(sX,eX),math.min(sZ,eZ),not tMode.overwrite)
      sync(s,"Paste")
      renderArea(sX,sZ,eX,eZ,true)
    elseif type(layer) == "number" then
      codeEnv.blueprint[layer]:paste(calcFunc(sX,sZ,eX,eZ,color),math.min(sX,eX),math.min(sZ,eZ),not tMode.overwrite)
    else
      error("Expected layer, got "..type(layer),2)
    end
  end
}
return tool
