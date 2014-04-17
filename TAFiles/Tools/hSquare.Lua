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
  local points = class.layer.new(2)
  for iX = x.min,x.max do
    points[iX][z.min] = color
    points[iX][z.max] = color
  end
  for iZ = z.min,z.max do
    points[x.min][iZ] = color
    points[x.max][iZ] = color
  end
  return points
end

local tool = {
  menuOrder = 2, --menu order, 1 being top
  selectFunc = function(button)
    tTool.change("hSquare",1,2)
  end,
  renderFunc = function(event,button,x,z,color,layer)
    local s = tTool.shape
    if event == "mouse_click" then
      if button == 1 then
        s.sX = x+tTerm.scroll.x
        s.sZ = z+tTerm.scroll.z
        if s.eX then
          screen:delLayer(screen.layers.toolsOverlay)
        end
        s.eX = false
        s.eZ = false
      elseif s.eX then --button 2
        tBlueprint[tTerm.scroll.layer]:paste(s.l,math.min(s.sX,s.eX)-1,math.min(s.sZ,s.eZ)-1,tMode.overwrite)
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
}
return tool