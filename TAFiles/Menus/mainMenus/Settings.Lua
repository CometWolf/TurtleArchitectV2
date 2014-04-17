local menu
menu = {
  [1] = {
    name = "Update",
    func = function()
      if not fs.exists(tFile.installer) then
        local res = http.paste.get(tPaste.program,tFile.installer)
        if not res then
          input"Failed to download installer script from pastebin!"
          return
        end
      end
      fs.delete(tFile.folder)
      fs.delete(tFile.program)
      term.clear()
      term.setCursorPos(1,1)
      term.setTextColor(colors.white)
      term.setBackgroundColor(colors.white)
      shell.run(tFile.installer,tFile.program:match"^(.+/).-$")
      return
    end
  },
  [2] = {
    name = "Built mode",
    func = function()
      local button = input(
        [[
Built mode let's you draw/see blocks marked as built. This means a turtle will consider these blocks already built, and ignore them.
Built render mode: ]]..(tMode.builtRender and "ON" or "OFF")..[[ 
Built draw mode: ]]..(tMode.builtDraw and "ON" or "OFF"),
        {
          "Cancel",
          (tMode.builtRender and "Render OFF" or "Render ON"),
          (tMode.builtDraw and "Draw OFF" or "Draw ON")
        }
      )
      if button == "Render ON" then
        tMode.builtRender = true
        scroll()
      elseif button == "Render OFF" then
        tMode.builtRender = false
        scroll()
      elseif button == "Draw ON" then
        tMode.builtDraw = true
      elseif button == "Draw OFF" then
        tMode.builtDraw = false
      end
    end
  },
  [3] = {
    name = "Grid mode",
    func = function()
      local button = input(
        [[
Grid mode renders a grid line ontop of your blueprint, for ease of visualization
Grid mode: ]]..(tMode.grid and "ON" or "OFF"),
        {
          "Cancel",
          (tMode.grid and "Grid OFF" or "Grid ON"),
        }
      )
      if button == "Grid ON" then
        tMode.grid = true
        local canvas = tTerm.canvas
        screen:setLayer(screen.layers.gridBorder)
        screen:setCursorPos(1,1)
        screen:setBackgroundColor(tColors.gridBorder)
        screen:setTextColor(tColors.gridBorderText)
        screen:write" "
        local nextChar = 1
        for i=2,canvas.eX do
          screen:write(string.format(nextChar))
          nextChar = nextChar+1
          nextChar = (nextChar < 10 and nextChar or 0)
        end
        screen:setCursorPos(1,2)
        nextChar = 1
        for i=2,canvas.eZ do
          screen:setCursorPos(1,i)
          screen:write(string.format(nextChar))
          nextChar = nextChar+1
          nextChar = (nextChar < 10 and nextChar or 0)
        end
        canvas.sX = canvas.sX+1
        canvas.tX = canvas.eX-canvas.sX
        canvas.sZ = canvas.sZ+1
        canvas.tZ = canvas.eZ-canvas.sZ
        local view = tTerm.viewable
        view.mX = view.mX+1
        view.mZ = view.mZ+1
        view.eX = view.sX+tTerm.canvas.tX
        view.eZ = view.sZ+tTerm.canvas.tZ
        scroll()
      elseif button == "Grid OFF" then
        tMode.grid = false
        local canvas = tTerm.canvas
        canvas.sX = canvas.sX-1
        canvas.tX = canvas.eX-canvas.sX
        canvas.sZ = canvas.sZ-1
        canvas.tZ = canvas.eZ-canvas.sZ
        local view = tTerm.viewable
        view.mX = view.mX-1
        view.mZ = view.mZ-1
        view.eX = view.sX+tTerm.canvas.tX
        view.eZ = view.sZ+tTerm.canvas.tZ
        for i=1,canvas.eX do
          screen:delPoint(i,1,screen.layers.gridBorder)
        end
        for i=1,canvas.eZ do
          screen:delPoint(1,i,screen.layers.gridBorder)
        end
        scroll()
      end
    end
  },
  [4] = {
    name = "Background layer",
    func = function()
      local button,tRes = input(
        [[
BGL mode renders the specified layer underneath the layer you are currently viewing. This makes comparisons a breeze.
BGL mode: ]]..(tMode.backgroundLayer and "ON" or "OFF"),
        {
          "Cancel",
          (tMode.backgroundLayer and "BGL OFF" or "BGL ON"),
          (tMode.backgroundLayer and "BGL change" or nil),
        },
        {
          {
            name = "BGL",
            value = math.max(tTerm.scroll.layer-1,1),
            accepted = "%d"
          },
        }
      )
      if button == "BGL ON"
      or button == "BGL change"
      or button == "Ok" then
        tMode.backgroundLayer = tBlueprint[tRes.BGL]
        scroll()
      elseif button == "BGL OFF" then
        tMode.backgroundLayer = false
        scroll()
      end
    end
  },
  [5] = {
    name = "Overwrite mode",
    func = function()
      local button = input(
        [[
Overwrite mode lets you draw over any color. If it's off, you may only draw on blank areas(white).
Overwrite mode: ]]..(tMode.overwrite and "ON" or "OFF"),
        {
          "Cancel",
          (tMode.overwrite and "Overwrite OFF" or "Overwrite ON"),
        }
      )
      if button == "Overwrite ON" then
        tMode.overwrite = true
      elseif button == "Overwrite OFF" then
        tMode.overwrite = false
      end
    end
  },
  [6] = {
    name = "About",
    func = function()
      input([[
Turtle Architect 2.0.
This software lets you draw your Minecraft constructions on your computer, and have your turtle build it wherever you desire. Files may easily be saved or even uploaded to Pastebin, for later use.
Developed by CometWolf.
]]
      )
    end
  },
  [7] = {
    name = "Quit",
    func = function()
      term.setTextColor(colors.white)
      term.setBackgroundColor(colors.black)
      term.clear()
      term.setCursorPos(1,1)
      error()
    end
  },
}
return menu