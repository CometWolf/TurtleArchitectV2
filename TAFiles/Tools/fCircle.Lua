local calcFunc = function(x1,z1,x2,z2)
  local function round(num)
    if num+0.5 > math.ceil(num) then
      return math.ceil(num)
    else
      return math.floor(num)
    end
  end
  local x = {
    max = math.max(x1,x2),
    min = math.min(x1,x2)
  }
  x.rad = round((x.max-x.min)/2)
  x.center = x.rad+x.min
  local z = {
    max = math.max(z1,z2),
    min = math.min(z1,z2)
  }
  z.rad = round((z.max-z.min)/2)
  z.center = z.rad+z.min
  local qPoints = class.matrix.new(2)
  local radStep = 1/((1.5*x.rad)+(1.5*z.rad)/2)
  for angle = 1, math.pi+radStep, radStep do
    local pX = round(math.cos(angle)*x.rad)
    local pZ = round(math.sin(angle)*z.rad)
    qPoints[pX][pZ] = true
  end
  local fPoints = class.matrix.new(2)
  for pX,tZ in pairs(qPoints) do
    for pZ in pairs(tZ) do
      for i=-1,1,2 do
        for j=-1,1,2 do
          local pX = x.center + i*pX
          local pZ = z.center + j*pZ
          fPoints[pX][pZ] = true
         end
      end
    end
  end
  return fPoints
end

local tool = {
  menuOrder = 5, --menu order, 1 being top
  selectFunc = function(button)
    tTool.change("fCircle",button)
  end,
  renderFunc = function(event,button,x,z,color)
    if button == 1 then
      if event == "mouse_click" then
        tTool.circle[1] = {
          x = x+tTerm.scroll.x,
          z = z+tTerm.scroll.z
        }
        if tTool.circle[2] then
          screen:delLayer(2)
        end
      else
        tTool.circle[2] = {
          x = x+tTerm.scroll.x,
          z = z+tTerm.scroll.z,
        }
        local c1 = tTool.circle[1]
        local c2 = tTool.circle[2]
        screen:delLayer(2)
        screen:setLayer(screen.layers.toolsOverlay)
        screen:setBackgroundColor(color)
        tTool.circle.points = calcFunc(c1.x,c1.z,c2.x,c2.z)
      end
    end
  end,
}
return tool