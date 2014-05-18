local calcFunc = function(x1,z1,x2,z2,color)
  local x = {
    max = math.max(x1,x2),
    min = math.min(x1,x2)
  }
  x.max = x.max-x.min+1
  x.min = 1
  x.rad = math.round((x.max-x.min)/2)
  x.center = x.rad+x.min
  local z = {
    max = math.max(z1,z2),
    min = math.min(z1,z2)
  }
  z.max = z.max-z.min+1
  z.min = 1
  z.rad = math.round((z.max-z.min)/2)
  z.center = z.rad+z.min
  local points = class.layer.new()
  local radStep = 1/((1.5*x.rad)+(1.5*z.rad)/2)
  for angle = 1, math.pi+radStep, radStep do
    local pX = math.round(math.cos(angle)*x.rad)
    local pZ = math.round(math.sin(angle)*z.rad)
    for i=-1,1,2 do
      for j=-1,1,2 do
        points[x.center + i*pX][z.center + j*pZ] = color
      end
    end
  end
  return points
end

local tool
tool = {
  menuOrder = 4, --menu order, 1 being top
  enabled = true,
  help = function(clickButton)
    local button = input(
      "The hollow circle tool lets you draw a hollow circle by left clicking a point and dragging to the opposite point. When you are satisfied, simply right click to draw it on the blueprint",
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
    tTool.change("hCircle",1,2)
  end,
  renderFunc = function(event,button,x,z,color)
    local c = tTool.shape
    if event == "mouse_click" then
      if button == 1 then
        c.sX = x+tTerm.scroll.x
        c.sZ = z+tTerm.scroll.z
        if c.eX then
          screen:clearLayer(screen.layers.toolsOverlay)
        end
        c.eX = false
        c.eZ = false
      elseif c.eX then --button 2
        c.layer = tTerm.scroll.layer
        sync(c,"Paste")
        tBlueprint[tTerm.scroll.layer]:paste(c.l,math.min(c.sX,c.eX),math.min(c.sZ,c.eZ),not tMode.overwrite)
        renderArea(c.sX,c.sZ,c.eX,c.eZ,true)
        tTool.shape = {}
        renderToolOverlay()
      end
    elseif button == 1 and c.sX then --drag
      c.eX = x+tTerm.scroll.x
      c.eZ = z+tTerm.scroll.z
      c.l = calcFunc(c.sX,c.sZ,c.eX,c.eZ,color)
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
    if codeEnv.settings.direct then
      if type(layer) == "table" and layer.paste then
        layer:paste(calcFunc(sX,sZ,eX,eZ,color),math.min(sX,eX),math.min(sZ,eZ),not tMode.overwrite)
      else
        local c = {
          sX = sX,
          sZ = sZ,
          eX = eX,
          eZ = eZ,
          layer = layer,
          l = calcFunc(sX,sZ,eX,eZ,color)
        }
        tBlueprint[layer]:paste(c.l,math.min(sX,eX),math.min(sZ,eZ),not tMode.overwrite)
        sync(c,"Paste")
        renderArea(sX,sZ,eX,eZ,true)
      end
    elseif type(layer) == "table" and layer.paste then
      layer:paste(calcFunc(sX,sZ,eX,eZ,color),math.min(sX,eX),math.min(sZ,eZ),not tMode.overwrite)
    elseif type(layer) == "number" then
      codeEnv.blueprint[layer]:paste(calcFunc(sX,sZ,eX,eZ,color),math.min(sX,eX),math.min(sZ,eZ),not tMode.overwrite)
    end
  end
}
return tool