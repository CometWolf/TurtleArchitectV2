local rightClickFunc = function(name,button) --used for modularity's sake
  for _i,v in ipairs(tMenu.rightClick.select) do
    if v.name == name then
      return v.enabled() and v.func(button)
    end
  end
  return false
end

local shortcuts = {
  [46] = function(button) --C
    rightClickFunc"Copy"
  end,
  [45] = function(button) --X
    rightClickFunc"Cut"
  end,
  [47] = function(button) --V
    rightClickFunc"Paste"
  end,
  [19] = function(button) --R
    rightClickFunc("Recolor",button)
  end,
  [48] = function(button) --B
    rightClickFunc"Mark built"
  end,
  [22] = function(button) --U
    rightClickFunc"Mark unbuilt"
  end,
}
local tool
tool = {
  menuOrder = 9, --menu order, 1 being top
  enabled = true,
  help = function(clickButton)
    local button = window.text(
      "The select tool has a myriad of functions.\nLeft click and drag to select an area, then right click to open up the selection menu. Here you can cut, copy, delete, recolor and change the built status of your current selection",
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
    tTool.change("Select",1,2)
    for k,v in pairs(shortcuts) do
      ctrlShortcuts.active[k] = v
    end
  end,
  deselectFunc = function()
    ctrlShortcuts.active = {}
    for k,v in pairs(ctrlShortcuts.default) do
      ctrlShortcuts.active[k] = v
    end
  end,
  renderFunc = function(event,button,x,z,color)
    if button == 1 then
      screen:setLayer(screen.layers.toolsOverlay)
      local c = tTool.clipboard
      local t = tTool.select
      if c then
        c.sX = x+tTerm.scroll.x
        c.sZ = z+tTerm.scroll.z
        c.eX = c.sX+c.lX-1
        c.eZ = c.sZ+c.lZ-1
      elseif event == "mouse_click" then
        t.layer = tTerm.scroll.layer
        t.sX = x+tTerm.scroll.x
        t.sZ = z+tTerm.scroll.z
        t.eX = nil
        t.eZ = nil
      else --drag
        t.eX = x+tTerm.scroll.x
        t.eZ = z+tTerm.scroll.z
      end
      renderToolOverlay()
      tTimers.blink.id = os.startTimer(tTimers.blink.time)
    else --right click
      tMenu.rightClick.render("select",x,z)
    end
  end
}
return tool
