local menu
menu = {
  enabled = true,
  [1] = {
    name = "Update",
    enabled = _G.http and true,
    help = function()
      window.text"Updates Turtle Architect to the latest version"
    end,
    func = function()
      if not fs.exists(tFile.installer) then
        local res = http.paste.get(tPaste.program,tFile.installer)
        if not res then
          window.text"Failed to download installer script from pastebin!"
          return
        end
      end
      local button = window.text(
        "All un-saved progress will be lost, continue?",
        {
          "No",
          "Yes"
        }
      )
      if button == "No" then
        return
      end
      fs.delete(tFile.menuFolder)
      fs.delete(tFile.classFolder)
      fs.delete(tFile.toolFolder)
      fs.delete(tFile.settings)
      fs.delete(tFile.program)
      term.clear()
      term.setCursorPos(1,1)
      term.setTextColor(colors.white)
      term.setBackgroundColor(colors.black)
      shell.run(tFile.installer,tFile.program:match"^(.+/).-$")
      error"Update"
    end
  },
  [2] = {
    name = "Built mode",
    enabled = true,
    help = function()
      window.text"Built mode let's you draw/see blocks marked as built. This means a turtle will consider these blocks already built, and ignore them."
    end,
    func = function()
      local button = window.text(
        [[Built mode let's you draw/see blocks marked as built. This means a turtle will consider these blocks already built, and ignore them.
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
    enabled = true,
    help = function()
      window.text"Grid mode renders a grid line ontop of your blueprint, for ease of visualization."
    end,
    func = function()
      local button = window.text(
        [[Grid mode renders a grid line ontop of your blueprint, for ease of visualization
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
    enabled = true,
    help = function()
      window.text"Background layer mode renders the specified layer in gray underneath the layer you are currently viewing. This makes comparisons a breeze."
    end,
    func = function()
      local button,tRes = window.text(
        [[BGL mode renders the specified layer underneath the layer you are currently viewing. This makes comparisons a breeze.
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
    enabled = true,
    help = function()
      window.text"Overwrite mode lets you draw over any color. If it's off, you may only draw on blank areas(white)."
    end,
    func = function()
      local button = window.text(
        [[Overwrite mode lets you draw over any color. If it's off, you may only draw on blank areas(white).
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
    name = "Sync mode",
    enabled = true,
    help = function()
      window.text"Sync mode syncs the blueprint in real-time across multiple computers. If you sync with turtles, they can be ordered to build the blueprint together"
    end,
    func = function()
      local synced = ""
      for id in pairs(tMode.sync.ids) do
        synced = synced..id..","
      end
      local button, tRes, reInput= window.text(
        [[Sync mode syncs the blueprint in real-time across multiple computers.
Synced: ]]..(tMode.sync.amount > 0 and synced or "None"),
        {
          "Cancel",
          (tMode.sync.amount > 0 and "Resync" or "Sync"),
          (tMode.sync.amount > 0 and "Desync" or nil)
        },
        {
          {
            name = "Sync IDs",
            value = os.id,
            accepted = "[%d,]",
          },
        },
        false,
        true
      )
      while button ~= "Cancel" do
        if button == "Sync"
        or button == "Resync"
        or button == "Ok" then
          tMode.sync = {
            ids = {},
            amount = 0,
            turtles = 0
          }
          if not tRes["Sync IDs"] then
            button,tRes,reInput = rewindow.text"Missing sync partner ID"
          else
            local syncIds = {}
            local faultyIds = true
            for id in string.gmatch(string.format(tRes["Sync IDs"]),"%d+") do
              syncIds[tonumber(id)] = true
              faultyIds = false
            end
            if faultyIds then
              button,tRes,reInput = rewindow.text"Faulty IDs!"
            else
              tMode.sync.amount = 0
              tMode.sync.ids = {}
              rednet.connect(
                syncIds,
                "Sync",
                100,
                function(id,data)
                  tMode.sync.ids[id] = data.turtle and "turtle" or "computer"
                  tMode.sync.amount = tMode.sync.amount+1
                  tMode.sync.turtles = tMode.sync.turtles+(data.turtle and 1 or 0)
                  rednet.send(
                    id,
                    "Sync edit",
                    {
                      type = "Blueprint load",
                      blueprint = tBlueprint,
                      blueprintName = tFile.blueprint
                    }
                  )
                  sync({sync = tMode.sync},"Ids")
                  local timerId = os.startTimer(10)
                   if data.turtle then
                     renderSideBar()
                   end
                  window.text(
                    "Successfully synced with "..(data.turtle and "Turtle" or "Computer").." ID "..id,
                    false,
                    false,
                    {
                      timer = function(tEvent)
                        if tEvent[2] == timerId then
                          return true
                        end
                      end
                    }
                  )
                end
              )
              return
            end
          end
        elseif button == "Desync" then
          rednet.send(tMode.sync.ids,"Sync OFF")
          tMode.sync.turtles = 0
          tMode.sync.amount = 0
          tMode.sync.ids = {}
          renderSideBar()
          return
        end
      end
    end
  },
  [7] = {
    name = "About",
    enabled = true,
    help = function()
      window.text"Tells the story of how awesome i am"
    end,
    func = function()
      window.text([[Turtle Architect 2.0.
This software lets you draw your Minecraft constructions on your computer, and have your turtle build it wherever you desire. Files may easily be saved or even uploaded to Pastebin, for later use.
Developed by CometWolf.
]]
      )
    end
  },
  [8] = {
    name = "Quit",
    enabled = true,
    func = function()
      error("Exit",0)
    end
  },
}
return menu