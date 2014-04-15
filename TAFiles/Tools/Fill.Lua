local tool = {
  menuOrder = 6, --menu order, 1 being top
  selectFunc = function(button) --called when the tool is selected
    tTool.change("Fill",button) --sets the tool on (button) to "Fill"
  end,
  renderFunc = function(event,button,x,z,color,layer) --called when the tool is used
    local scrollX,scrollZ = tTerm.scroll.layer,tTerm.scroll.x,tTerm.scroll.z
    local replaceColor = tBlueprint[tTerm.scroll.layer][x+scrollX][z+scrollZ]
    if fillColor == replaceColor then
      return
    end
    drawPoint(x,z,color)
    local tPoints = class.matrix.new(2)
    local loops = 0
    local tAffectedPoints = {
      [1] = {
        x = x,
        z = z
      }
    }
    while #tAffectedPoints > 0 do
      if loops%50 == 0 then
        sleep(0.05)
      end
      for i=-1,1,2 do
        local x = tAffectedPoints[1]["x"]+i
        local z = tAffectedPoints[1]["z"]
        if not tPoints[x][z]
        and tBlueprint[layer][x+scrollX][z+scrollZ] == replaceColor then
          drawPoint(x,z,color)
          tPoints[x][z] = true
          table.insert(tAffectedPoints,{["x"] = x,["z"] = z})
        end
        x = tAffectedPoints[1]["x"]
        z = tAffectedPoints[1]["z"]+i
        if not tPoints[x][z]
        and tBlueprint[layer][x+scrollX][z+scrollZ] == replaceColor then
          drawPoint(x,z,color)
          tPoints[x][z] = true
          table.insert(tAffectedPoints,{["x"] = x,["z"] = z})
        end
      end
      table.remove(tAffectedPoints,1)
      loops = loops+1
    end
    
  end
}
return tool