local calcFunc = function(x1,z1,x2,z2,color)
  local x = {
    max = math.max(x1,x2),
    min = math.min(x1,x2)
  }
  x.rad = math.round((x.max-x.min)/2)
  x.center = x.rad+x.min
  local z = {
    max = math.max(z1,z2),
    min = math.min(z1,z2)
  }
  z.rad = math.round((z.max-z.min)/2)
  z.center = z.rad+z.min
  local qPoints = class.matrix.new(2)
  local radStep = 1/((1.5*x.rad)+(1.5*z.rad)/2)
  for angle = 1, math.pi+radStep, radStep do
    local pX = math.round(math.cos(angle)*x.rad)
    local pZ = math.round(math.sin(angle)*z.rad)
    qPoints[pX][pZ] = true
  end
  local fPoints = class.layer.new(2)
  for pX,tZ in pairs(qPoints) do
    for pZ in pairs(tZ) do
      for i=-1,1,2 do
        for j=-1,1,2 do
          local pX = x.center + i*pX
          local pZ = z.center + j*pZ
          fPoints[pX][pZ] = color
         end
      end
    end
  end
  return fPoints
end

local tool = {
  menuOrder = 4, --menu order, 1 being top
  selectFunc = function(button)
    tTool.change("hCircle",button)
  end,
  renderFunc = function(event,button,x,z,color)
    if button == 1 then
      local c = tTool.circle
      if event == "mouse_click" then
        c.sX = x+tTerm.scroll.x
        c.sZ = z+tTerm.scroll.z
        if c.eX then
          screen:delLayer(screen.layers.toolsOverlay)
        end
        c.eX = false
        c.eZ = false
      else
        c.eX = x+tTerm.scroll.x
        c.eZ = z+tTerm.scroll.z
        screen:delLayer(screen.layers.toolsOverlay)
        screen:setLayer(screen.layers.toolsOverlay)
        screen:setBackgroundColor(color)
        c.l = calcFunc(c.sX,c.sZ,c.eX,c.eZ,color)
        renderToolOverlay()
      end
    end
  end,
}
return tool