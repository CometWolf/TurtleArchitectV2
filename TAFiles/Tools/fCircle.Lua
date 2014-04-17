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
  local points = class.layer.new(2)
  local radStep = 1/((1.5*x.rad)+(1.5*z.rad)/2)
  for angle = 1, math.pi+radStep, radStep do
    local pX = math.round(math.cos(angle)*x.rad)
    local pZ = math.round(math.sin(angle)*z.rad)
    for iX = x.center-pX,x.center+pX do
      for i=-1,1,2 do
        points[iX][z.center+(pZ*i)] = color
      end
    end
    for iZ = z.center-pZ,z.center+pZ do
      for i=-1,1,2 do
        points[x.center+(pX*i)][iZ] = color
      end
    end
  end
  return points
end

local tool = {
  menuOrder = 5, --menu order, 1 being top
  selectFunc = function(button)
    tTool.change("fCircle",1,2)
  end,
  renderFunc = function(event,button,x,z,color)
    local c = tTool.shape
    if event == "mouse_click" then
      if button == 1 then
        c.sX = x+tTerm.scroll.x
        c.sZ = z+tTerm.scroll.z
        if c.eX then
          screen:delLayer(screen.layers.toolsOverlay)
        end
        c.eX = false
        c.eZ = false
      elseif c.eX then --button 2
        tBlueprint[tTerm.scroll.layer]:paste(c.l,math.min(c.sX,c.eX)-1,math.min(c.sZ,c.eZ)-1,not tMode.overwrite)
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
}
return tool