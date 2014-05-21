local tool
tool = {
  menuOrder = 7, --menu order, 1 being top
  enabled = true,
  help = function(clickButton)
    local button = window.text(
      "The fill tool will replace the block you click on and any block connected to it of the same color, to the color it has equipped. It will not go beyond the visible canvas however",
      {
        "Ok",
        "Equip"
      }
    )
    if button == "Equip" then
      tool.selectFunc(clickButton)
    end
  end,
  selectFunc = function(button) --called when the tool is selected
    tTool.change("Fill",button) --sets the tool on (button) to "Fill"
  end,
  renderFunc = function(event,button,x,z,color,layer) --called when the tool is used
    local replaceColor = tBlueprint[tTerm.scroll.layer][x+tTerm.scroll.x][z+tTerm.scroll.z]
    if color == replaceColor then
      return
    end
    drawPoint(x,z,color)
    local loops = 0
    local tAffectedPoints = {
      [1] = {
        x = x+tTerm.scroll.x,
        z = z+tTerm.scroll.z
      }
    }
    while #tAffectedPoints > 0 do
      if loops%200 == 0 then
        sleep(0.05)
      end
      for i=-1,1,2 do
        local x = tAffectedPoints[1]["x"]+i
        local z = tAffectedPoints[1]["z"]
        if tBlueprint[layer][x][z] == replaceColor
        and x >= tTerm.viewable.sX and x <= tTerm.viewable.eX 
        and z >= tTerm.viewable.sZ and z <= tTerm.viewable.eZ then
          drawPoint(x,z,color,layer,true,true)
          table.insert(tAffectedPoints,{["x"] = x,["z"] = z})
        end
        x = tAffectedPoints[1]["x"]
        z = tAffectedPoints[1]["z"]+i
        if tBlueprint[layer][x][z] == replaceColor
        and x >= tTerm.viewable.sX and x <= tTerm.viewable.eX 
        and z >= tTerm.viewable.sZ and z <= tTerm.viewable.eZ then
          drawPoint(x,z,color,layer,true,true)
          table.insert(tAffectedPoints,{["x"] = x,["z"] = z})
        end
      end
      table.remove(tAffectedPoints,1)
      loops = loops+1
    end
  end
}
return tool