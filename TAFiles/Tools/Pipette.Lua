local tool
tool = {
  menuOrder = 2, --menu order, 1 being top
  enabled = true,
  help = function(clickButton)
    local button = window.text(
      "The pipette is used to select a color from the canvas. Simply click on an already drawn block, and it will switch to that color as well as revert to the previously equipped tool",
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
    tTool.change("Pipette",button)
  end,
  renderFunc = function(event,button,x,z,color,layer)
    tTool[button].color = tBlueprint[layer][x+tTerm.scroll.x][z+tTerm.scroll.z]
    tTool.change(tTool[button].prevTool,button)
  end
}
return tool