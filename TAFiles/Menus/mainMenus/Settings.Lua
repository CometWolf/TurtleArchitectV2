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
      if loadFile(tFile.installer) then
        error("Update",0)
      end
    end
  },
  [2] = {
    name = "Color settings",
    enabled = true,
    help = function()
      window.text("Change the programs color settings. Every color of the GUI may be changed here, with the exception of the actual drawing colors. These settings are saved between sessions.")
    end,
    func = function()
      local colorSelection = {}
      for k,v in pairs(tColors) do
        if type(v) == "number" then
          k = k:gsub("(%u)",function(l) return " "..l:lower() end)
          k = k:sub(1,1):upper()..k:sub(2)
          colorSelection[#colorSelection+1] = {
            text = k,
            uText = v ~= tColors.scrollBoxSelectText and tColors.scrollBoxSelectText or colors.black,
            uBackground = v
          }
        end
      end
      while true do
        local button,selected = window.scroll("Select the color you wish to change",colorSelection)
        if button == "Cancel" then
          return
        end
        local selectedColor = dialogue.selectColor("Select new "..selected.." color")
        if selectedColor ~= "Cancel" then
          selectedColor = string.gsub(
            string.lower(selectedColor:sub(1,1))..selectedColor:sub(2),
            "%s.",
            function(match)
              return string.upper(match:sub(2)) 
            end
          )
          for k,v in pairs(colorSelection) do
            if v.text == selected then
              v.uText = colors[selectedColor] ~= tColors.scrollBoxSelectText and tColors.scrollBoxSelectText or colors.black
              v.uBackground = colors[selectedColor]
              break
            end
          end
          selected = string.gsub(
            string.lower(selected:sub(1,1))..selected:sub(2),
            "%s.",
            function(match)
              return string.upper(match:sub(2)) 
            end
          )
          if selected == "canvas" then
            colorKey[" "] = colors[selectedColor]
            tBlueprint[tTerm.scroll.layer]:render()
          end
          tColors[selected] = colors[selectedColor]
          local file = class.fileTable.new(tFile.settings)
          local line = file:find("    "..selected.." = colors")
          file:write("    "..selected.." = colors."..selectedColor..", "..(file[line]:match"%-%-(.+)$" and "--"..file[line]:match"%-%-(.+)$" or ""),line)
          file:save()
          renderSideBar()
          renderBottomBar()
        end
      end
    end
  },
  [3] = {
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
  [4] = {
    name = "Grid mode",
    enabled = true,
    help = function()
      window.text"Grid mode renders a grid line ontop of your blueprint, for ease of visualization."
    end,
    func = function()
      if tMode.grid then
        tMode.grid = false
        removeGrid()
        local file = class.fileTable.new(tFile.settings)
        local line = file:find("  grid = true,",true)
        file:write("  grid = false,",line)
        file:save()
      else
        tMode.grid = true
        renderGrid()
        local file = class.fileTable.new(tFile.settings)
        local line = file:find("  grid = false,",true)
        file:write("  grid = true,",line)
        file:save()
      end
    end
  },
  [5] = {
    name = "Grid major",
    enabled = true,
    help = function()
      window.text"Change the size of the major grid marker (the darker marker)"
    end,
    func = function()
      local button,tRes,reInput = window.text(
        "Change the size of the major grid marker",
        {
          "Cancel",
          "Ok"
        },
        {
          {
            name = "Major",
            value = tMode.gridMajor,
            accepted = "%d"
          },
        },
        nil,
        true
      )
      while true do
        if button == "cancel" then
          return
        elseif not tRes.Major then
          button,tRes,reInput = reInput("Missing major parameter!")
        else
          if tRes.Major ~= tMode.gridMajor then
            tMode.gridMajor = tRes.Major
            local file = class.fileTable.new(tFile.settings)
            local line = file:find("  gridMajor = %d-,")
            file:write("  gridMajor = "..tMode.gridMajor..",",line)
            file:save()
            if tMode.grid then
              scroll()
            end
          end
          return
        end
      end
    end
  },
  [6] = {
    name = "Background layer",
    enabled = true,
    help = function()
      window.text"Background layer mode renders the specified layer in gray underneath the layer you are currently viewing. This makes comparisons a breeze."
    end,
    func = function()
      local button,tRes,reInput = window.text(
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
        },
        nil,
        true
      )
      if button == "BGL ON"
      or button == "BGL change"
      or button == "Ok" then
        if not tBlueprint[tRes.BGL] then
          button,tRes,reInput = reInput("Layer ("..tRes.BGL..") does not exist!")
        else
          tMode.backgroundLayer = tBlueprint[tRes.BGL]
          scroll()
        end
      elseif button == "BGL OFF" then
        tMode.backgroundLayer = false
        scroll()
      end
    end
  },
  [7] = {
    name = "Overwrite mode",
    enabled = true,
    help = function()
      window.text"Overwrite mode lets you draw over any color. If it's off, you may only draw on blank areas(white)."
    end,
    func = function()
      tMode.overwrite = not tMode.overwrite
    end
  },
  [8] = {
    name = "Hide menus",
    enabled = true,
    help = function()
      window.text"Hides all menus, leaving only the canvas. Press ctrl+H to re-enable menus."
    end,
    func = function()
      toggleMenus()
    end
  },
  [9] = {
    name = "Sync mode",
    enabled = function()
      return modem and true or false
    end,
    help = function()
      window.text"Sync mode syncs the blueprint in real-time across multiple computers. If you sync with turtles, they can be ordered to build the blueprint together"
    end,
    func = function()
      local synced = {}
      for id in pairs(tMode.sync.ids) do
        synced[id] = true
      end
      local inRange = {}
      rednet.send("All","Ping")
      tTimers.scan.start()
      local scanRes = window.text(
        {
          {
            text = "Scanning",
            renderTime = 0.2
          },
          {
            text = "Scanning.",
            renderTime = 0.2
          },
          {
            text = "Scanning..",
            renderTime = 0.2
          },
          {
            text = "Scanning...",
            renderTime = 0.2
          },
        },
        {
          "Cancel"
        },
        nil,
        {
          timer = function(tEvent)
            if tTimers.scan.ids[tEvent[2]] then
              return "Done"
            end
          end,
          modem_message = function(tEvent)
            if tEvent[3] == modemChannel
            and type(tEvent[5]) == "table" --All Turtle Architect messages are sent as tables
            and tEvent[5].rID[os.id] then
              local data = tEvent[5]
              if data.event == "Success"
              and data.type == "Ping" then
                inRange[#inRange+1] = {
                  text = data.turtle and data.sID.." - Turtle" or data.sID.." - Computer",
                  selected = tMode.sync.ids[data.sID] and true
                }
              end
            end
          end
        }
      )
      if scanRes == "Cancel" then
        return
      end
      if #inRange == 0 then
        window.text"No syncable computers in range!"
        return
      end
      local button,connectIds = window.scroll("Select sync IDs:",inRange,true)
      if button == "Cancel" then
        return
      end
      local syncIds = {}
      for i,id in ipairs(connectIds) do
        syncIds[tonumber(id:match"%d+")] = true
      end
      connectIds = nil
      local deSyncIds = {}
      local deSync
      for id in pairs(tMode.sync.ids) do
        if not syncIds[id] then
          deSyncIds[id] = true
          deSync = true
        else
          syncIds[id] = nil
        end
      end
      if deSync then
        rednet.disconnect(deSyncIds)
      end
      deSyncIds = nil
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
          if data.turtle and tMode.sync.turtles == 1 then
            renderSideBar()
          end
          window.text(
            "Successfully synced with "..(data.turtle and "Turtle" or "Computer").." ID "..id,
            false,
            false,
            {
              timer = function(tEvent)
                if tEvent[2] == timerId then
                  return "Ok"
                end
              end
            }
          )
        end
      )
    end
  },
  [10] = {
    name = "About",
    enabled = true,
    help = function()
      window.text"Tells the story of how awesome i am"
    end,
    func = function()
      window.text([[Turtle Architect 2.0.
This software lets you draw your Minecraft constructions on your computer, and have your turtle build it wherever you desire. Files may easily be saved or even uploaded to Pastebin, for later use.
Developed by CometWolf.

Use the help tool, found under the To menu, if you desire more information.
]]
      )
    end
  },
  [11] = {
    name = "Quit",
    enabled = true,
    func = function()
      error("Exit",0)
    end
  }
}
return menu
