local tool
tool = {
  menuOrder = 10, --menu order, 1 being top
  enabled = true,
  help = function()
    input"The tool you are currently using, displays help windows describing what things do when you click on any element of TA's UI"
  end,
  selectFunc = function(button)
    tTool.change("Help",button)
  end,
  renderFunc = function(event,button,x,z,color,layer)
    input"This is the canvas where you draw your creations. It's scrollable in all directions using the arrow keys."
  end
}
return tool