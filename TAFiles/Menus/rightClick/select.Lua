local menu
menu = {
  [1] = {
    name = "Cut",
    enabled = function()
      return tTool.select.eX and true
    end,
    select = true,
    help = function()
      window.text"Copies the current selection into the clipboard, and deletes it from the canvas"
    end,
    func = function()
      local t = tTool.select
      tTool.clipboard = tBlueprint[t.layer]:copy(t.sX,t.sZ,t.eX,t.eZ,true)
      sync(t,"Delete")
      tBlueprint[t.layer]:delete(t.sX,t.sZ,t.eX,t.eZ)
      renderArea(t.sX,t.sZ,t.eX,t.eZ,true)
      tTool.select = {}
    end
  },
  [2] = {
    name = "Copy",
    enabled = function()
      return tTool.select.eX and true
    end,
    help = function()
      window.text"Copies the current selection into the clipboard"
    end,
    func = function()
      local t = tTool.select
      tTool.clipboard = tBlueprint[t.layer]:copy(t.sX,t.sZ,t.eX,t.eZ,true)
      tTool.select = {}
      screen:clearLayer(screen.layers.toolsOverlay)
      local c = tTool.clipboard
      c.sX = c.sX+1
      c.sZ = c.sZ+1
      c.eX = c.eX+1
      c.eZ = c.eZ+1
      renderToolOverlay()
    end
  },
  [3] = {
    name = "Paste",
    enabled = function()
      return tTool.clipboard and true
    end,
    help = function()
      window.text"Draws the current clipboard to the blueprint"
    end,
    func = function()
      local c = tTool.clipboard
      c.layer = tTerm.scroll.layer
      sync(c,"Paste")
      tBlueprint[tTerm.scroll.layer]:paste(c.l,c.sX,c.sZ,not tMode.overwrite)
      renderArea(c.sX,c.sZ,c.eX,c.eZ,true)
      c.sX = c.sX+1
      c.sZ = c.sZ+1
      c.eX = c.eX+1
      c.eZ = c.eZ+1
      renderToolOverlay()
    end
  },
  [4] = {
    name = "Recolor",
    enabled = function()
      return tTool.select.eX and true or tTool.clipboard and true
    end,
    help = function()
      window.text"Recolors the currently selected area or the clipboard, to color equipped on the button you pressed with"
    end,
    func = function(button)
      local c = tTool.clipboard
      local color = tTool[button].color
      if c then
        c.l:recolor(color,1,1,c.lX,c.lZ)
        renderToolOverlay()
      else
        local t = tTool.select
        sync(t,"Recolor")
        tBlueprint[t.layer]:recolor(color,t.sX,t.sZ,t.eX,t.eZ)
        renderArea(t.sX,t.sZ,t.eX,t.eZ,true)
      end
    end
  },
  [5] = {
    name = "Flip vert",
    enabled = function()
      return tTool.select.eX and true or tTool.clipboard and true
    end,
    help = function()
      window.text"Flips the current selection or clipboard vertically(Z)"
    end,
    func = function()
      local t = tTool.select
      local c = tTool.clipboard
      if t.eX then
        local layer = tBlueprint[t.layer]
        local flip = layer:copy(t.sX,t.sZ,t.eX,t.eZ,true):flipZ(t.sX,t.sZ,t.eX,t.eZ)
        layer:paste(flip,t.sX,t.sZ)
        renderArea(t.sX,t.sZ,t.eX,t.eZ,true)
      else
        c.l = c.l:flipZ(1,1,c.lX,c.lZ)
        renderToolOverlay()
      end
    end
  },
  [6] = {
    name = "Flip hori",
    enabled = function()
      return tTool.select.eX and true or tTool.clipboard and true
    end,
    help = function()
      window.text"Flips the current selection or clipboard horizontally(X)"
    end,
    func = function()
      local t = tTool.select
      local c = tTool.clipboard
      if t.eX then
        local layer = tBlueprint[t.layer]
        local flip = layer:copy(t.sX,t.sZ,t.eX,t.eZ,true):flipX(t.sX,t.sZ,t.eX,t.eZ)
        layer:paste(flip,t.sX,t.sZ)
        renderArea(t.sX,t.sZ,t.eX,t.eZ,true)
      else
        c.l = c.l:flipX(1,1,c.lX,c.lZ)
        renderToolOverlay()
      end
    end
  },
  [7] = {
    name = "Mark built",
    enabled = function()
      return tTool.select.eX and true or tTool.clipboard and true
    end,
    help = function()
      window.text"Marks the current selection or clipboard as built, thus making the turtle skip it"
    end,
    func = function()
      local t = tTool.select
      local c = tTool.clipboard
      if t.eX then
        sync(t,"Mark built")
        tBlueprint[t.layer]:markBuilt(t.sX,t.sZ,t.eX,t.eZ)
        if tMode.renderBuilt then
          renderArea(t.sX,t.sZ,t.eX,t.eZ,true)
        end
      else
        c.l:markBuilt(1,1,c.lX,c.lZ)
        renderToolOverlay()
      end
    end
  },
  [8] = {
    name = "Mark unbuilt",
    enabled = function()
      return tTool.select.eX and true or tTool.clipboard and true
    end,
    help = function()
      window.text"Resets any build progress made within the current selection or clipboard"
    end,
    func = function()
      local t = tTool.select
      local c = tTool.clipboard
      if t.eX then
        sync(t,"Mark unbuilt")
        tBlueprint[t.layer]:markUnbuilt(t.sX,t.sZ,t.eX,t.eZ)
        if tMode.renderBuilt then
          renderArea(t.sX,t.sZ,t.eX,t.eZ,true)
        end
      else
        c.l:markUnbuilt(1,1,c.lX,c.lZ)
        renderToolOverlay()
      end
    end
  },
  [9] = {
    name = "Delete",
    enabled = function()
      return tTool.select.eX and true or tTool.clipboard and true
    end,
    help = function()
      window.text"Removes the current selection from the blueprint, or clears the clipbord"
    end,
    func = function()
      local t = tTool.select
      local c = tTool.clipboard
      if t.eX then
        sync(t,"Delete")
        tBlueprint[t.layer]:delete(t.sX,t.sZ,t.eX,t.eZ)
        renderArea(t.sX,t.sZ,t.eX,t.eZ,true)
      else
        tTool.clipboard = false
        screen:clearLayer(screen.layers.toolsOverlay)
      end
    end
  },
}

return menu