local common
common = { --common event handlers, these are always active
  timer = function(tEvent)
    local timerID = tEvent[2]
    if timerID == tTimers.blink.id then
      local toggle = tTimers.blink.toggle
      tTimers.blink.toggle = not toggle
      if toggle then
        renderToolOverlay()
      else
        screen:delLayer(screen.layers.toolsOverlay)
      end
      tTimers.blink.start()
    elseif timerID == tTimers.ctrl.id then
      tTimers.ctrl.pressed = false
    elseif timerID == tTimers.connectionPing.id then
      if rednet.connected.amount > 0 then
        rednet.send(
          rednet.connected.ids,
          "Ping",
          false,
          false,
          function(id)
            rednet.connected.ids[id] = nil
            local turtle = tMode.sync.ids[id] == "turtle"
            tMode.sync.turtles = tMode.sync.turtles-(turtle and 1 or 0)
            tMode.sync.amount = tMode.sync.ids[id] and tMode.sync.amount-1 or tMode.sync.amount
            tMode.sync.ids[id] = nil 
            if turtle and tMode.sync.turtles == 0 then
              renderSideBar()
            end
            input("Connection to computer ID "..id.." was lost.")
          end
        )
      end
      tTimers.connectionPing.start()
    elseif tTimers.modemRes.ids[timerID] then
      local func = tTransmissions.failure.timeout[timerID]
      if func then
        return func()
      end
    end
  end,
  peripheral = function(tEvent)
    local side = tEvent[2]
    if not modem and peripheral.getType(side) == "modem" and peripheral.call(side,"isWireless") then
      modem = peripheral.wrap(side)
      modem.open(modemChannel)
      modem.side = side
    elseif not glasses and peripheral.getType(side) == "openperipheral_glassesbridge" then
      glasses.bridge = peripheral.wrap(side)
      glasses.side = side
      screen:glassInit(glasses.bridge,glasses.size)
    end
  end,
  peripheral_detach = function(tEvent)
    local side = tEvent[2]
    if modem and side == modem.side then
      modem = nil
    elseif glasses and side == glasses.side then
      screen.glass = nil
    end
  end,
  chat_command = function(tEvent)
    local command = tEvent[2]:lower()
    local tCommand = {}
    for word in command:gmatch"%S+" do
      local num = tonumber(word)
      if num then
        tCommand[#tCommand+1] = num
      else
        tCommand[#tCommand+1] = word:lower()
      end
    end
    local menuName = string.upper(string.sub(tCommand[1],1,1))..string.sub(tCommand[1],2)
    if tCommand[1] == "resize" then
      local x,y = tCommand[2],tCommand[3]
      if type(x) == "number" and type(y) == "number" then
        screen:glassResize(x,y)
      end
    elseif tCommand[1] == "toggle" then
      if tCommand[2] == "follow" then
        glasses.followTurtle = not glasses.followTurtle
      elseif tcommand[2] == "minimal" then
        glasses.minimal = not glasses.minimal
      else
        
      end
    elseif tMenu.main[menuName] then
      if not tCommand[2] then
        renderMenu(menuName)
      else
        local funcName = table.concat(tCommand," ",2)
        funcName = string.upper(string.sub(funcName,1,1))..string.sub(funcName,2)
        for i=1,#tMenu.main[menuName].items do
          if tMenu.main[menuName].items[i].name:match(funcName) then
            tMenu.main[menuName].items[i].func()
          end
        end
      end
    elseif tMenu.open then
      local funcName = table.concat(tCommand," ",2)
      funcName = string.upper(string.sub(funcName,1,1))..string.sub(funcName,2)
      for i=1,#tMenu.main[menuName].items do
        if tMenu.main[menuName].items[i].name:match(funcName) then
          tMenu.main[menuName].items[i].func()
        end
      end
    end
  end,
  modem_message = function(tEvent)
    if tEvent[3] == modemChannel
    and type(tEvent[5]) == "table" --All Turtle Architect messages are sent as tables
    and tEvent[5].rID[os.id] then
      local data = tEvent[5]
      local event = data.event
      local senderId = data.sID
      local type = data.type
      if event == "Success" then
        local func = tTransmissions.success[type][senderId]
        if func then
          func(data)
        end
      elseif event == "Failure" then
        local func = tTransmissions.failure[type][senderId]
        if func then
          func(data)
        end
      elseif event == "Ping" then
        rednet.send(senderId,"Success",{type="Ping"})
      elseif event == "Init connection" then
        if type == "Sync" then
          local timeoutId = tTimers.inputTimeout.start()
          local button, tRes = input(
            "Computer ID "..senderId.." wants to initiate sync mode.",
            {
              "Deny",
              "Accept"
            },
            false,
            function(tEvent)
              if tEvent[1] == "timer" and
              tEvent[2] == timeoutId then
                return "Deny"
              end
            end
          )
          if button == "Accept" then
            local reRenderSideBar = tMode.sync.turtles > 0
            if tMode.sync.amount > 0 then
              rednet.disconnect(tMode.sync.ids)
            end
            rednet.connected.amount = rednet.connected.amount+1
            rednet.connected.ids[senderId] = true
            tMode.sync.amount = 1
            if data.turtle then
              tMode.sync.turtles = 1
              tMode.sync.ids = {[senderId] = "turtle"}
              if not reRenderSideBar then
                renderSideBar()
              end
            else
              tMode.sync.turtles = 0
              tMode.sync.ids = {[senderId] = "computer"}
              if reRenderSideBar then
                renderSideBar()
              end
            end
            rednet.send(senderId,"Success",{type = event,turtle = turtle and true})
          else
            rednet.send(senderId,"Failure",{type = event})
          end
        end
      elseif event == "Sync edit"
      and tMode.sync.ids[senderId] then
        if type == "Ids" then
          tMode.sync = data.sync
          tMode.sync.ids[os.id] = nil
          tMode.sync.ids[senderId] = true
          if turtle then
            tMode.sync.turtles = tMode.sync.turtles-1
          end
          for k,v in pairs(tMode.sync.ids) do
            if not rednet.connected.ids[k] then
              rednet.connected.ids[k] = true
              rednet.connected.amount = rednet.connected.amount+1
            end
          end
        elseif type == "Paste" then --this is used for most tools
          tBlueprint[data.layer]:paste(data.l,data.sX,data.sZ,data.merge)
          renderArea(data.sX,data.sZ,data.eX,data.eZ,true)
        elseif type == "Point" then --probably brush
          tBlueprint[data.layer][data.x][data.z] = data.color
          if glasses.bridge and glasses.followTurtle then
            scroll(data.layer,data.x-math.floor(tTerm.canvas.tX/2),data.z-math.floor(tTerm.canvas.tZ/2),true,true)
          elseif tTerm.scroll.layer == data.layer then
            renderPoint(data.x,data.z,true)
          end
        elseif type == "Delete" then
          for iX = data.sX,data.eX do
            for iZ = data.sZ,data.eZ do
              tBlueprint[data.layer][iX][iZ] = nil
            end
          end
          renderArea(data.sX,data.sZ,data.eX,data.eZ,true)
        elseif type == "Recolor" then
          tBlueprint[data.layer]:recolor(data.color,data.sX,data.sZ,data.eX,data.eZ)
          renderArea(data.sX,data.sZ,data.eX,data.eZ)
        elseif type == "Mark built" then
          if data.blueprint then
            tBlueprint:markBuilt()
          else
            tBlueprint[data.layer]:markBuilt(data.sX,data.sZ,data.eX,data.eZ)
          end
          renderArea(data.sX,data.sZ,data.eX,data.eZ)
        elseif type == "Mark unbuilt" then
          tBlueprint[data.layer]:markUnbuilt(data.sX,data.sZ,data.eX,data.eZ)
          renderArea(data.sX,data.sZ,data.eX,data.eZ)
        elseif type == "Layer add" then
          while #tBlueprint < data.layer do
            tBlueprint[#tBlueprint+1] = class.layer.new()
          end
        elseif type == "Layer delete" then
          if data.layer then
            data.from = data.layer
            data.to = data.layer
          end
          for i=data.from,data.to do
            if i == 1 and #tBlueprint == 1 then
              tBlueprint[1] = tBlueprint[1].new()
            else
              table.remove(tBlueprint,i)
            end
          end
          scroll()
        elseif type == "Flip" then
          local flip = data.blueprint and tBlueprint or tBlueprint[data.layer]
          if data.dir == "X" then
            flip:flipX(data.sX,data.sZ,data.eX,data.eZ)
          else
            flip:flipZ(data.sX,data.sZ,data.eX,data.eZ)
          end
          renderArea(data.sX,data.sZ,data.eX,data.eZ)
        elseif type == "Blueprint load" then
          tBlueprint = class.blueprint.copy(data.blueprint)
          tFile.blueprint = data.blueprintName or nil
          scroll(1,0,0,true,true)
        elseif type == "Blueprint sub" then
          tBlueprint = tBlueprint:copy(data.sX,data.sZ,data.eX,data.eZ)
          tBlueprint:save(tFile.blueprint,true)
          for i=1,#tBlueprint do
            scroll(i,0,0,true) --i don't fucking know anymore, I GIVE UP
          end
          scroll(1,0,0,true,true)
        elseif type == "Colorslots load" then
          tBlueprint.colorsSlots = class.matrix.new(2,data.colorSlots)
        end
      elseif event == "Sync OFF"
      and tMode.sync.ids[senderId] then
        if tMode.sync.ids[senderId] then
          local turtle = tMode.sync.ids[senderId] == "turtle"
          tMode.sync.turtles = tMode.sync.turtles-(turtle and 1 or 0)
          tMode.sync.amount = tMode.sync.amount-1
          tMode.sync.ids[senderId] = nil
          rednet.connected.ids[senderId] = nil
          rednet.connected.amount = rednet.connected.amount-1
          if turtle and tMode.sync.turtles == 0 then
            renderSideBar()
          end
          input((turtle and "Turtle" or "Computer").." ID "..senderId.." has de-synced")
        end
      elseif event == "Turtle command" then
        local response = {
          type = event
        }
        if type == "Move" then
          cTurtle.moveToXYZ(data.x,data.y,data.z)
        elseif type == "Turn" then
          cTurtle.turn(data.dir)
        elseif type == "Get blueprint progress" then
          response.progress = loadProgress(data.blueprintName)
          rednet.send(senderId,"Success",response)
        elseif type == "Save blueprint progress" then
          saveProgress(data.blueprintName,data.progress)
        elseif type == "Build" then
          local oldSync = tMode.sync
          tMode.sync = {
            ids = {
              [senderId] = true
            },
            amount = 1,
            turtles = 0
          }
          build(tBlueprint,true)
          tMode.sync = oldSync
        end
      elseif event == "Turtle status" and not tIgnore[senderId] then
        if type == "Blocks required" then
          local button = input(
            "Turtle "..senderId.." requires more blocks to continue building",
            {
              "Cancel",
              "Ignore",
              "Ok"
            },
            false,
            {
              modem_message = function(tEvent)
                if tEvent[3] == modemChannel
                and type(tEvent[5]) == "table"
                and tEvent[5].rID[os.id] then
                  local data = tEvent[5]
                  local event = data.event
                  local senderId2 = data.sID
                  local type = data.type
                  if event == "Turtle status"
                  and type == "Restock" 
                  and senderId == senderId2 then
                    return "Cancel"
                  end
                end
              end
            }
          )
          if button == "Ok" then
            rednet.send(senderId,"Turtle command",{type == "Restock"})
          elseif button == "Ignore" then
            tIgnore[senderId] = true
          end
        end
      elseif event == "Blueprint transmission" then
        local timeoutId = tTimers.inputTimeout.start()
        local button, tRes, reInput = input(
          "Received blueprint "..tEvent[5].blueprintName.." from computer ID "..senderId,
          {
            "Ignore",
            "Save",
            "Load"
          },
          {
            {
              name = "File name",
              value = "/",
              accepted = "."
            },
          },
          {
            timer = function(tEvent)
              if tEvent[2] == timeoutId then
                return "Ignore"
              end
            end
          },
          true
        )
        while button ~= "Ignore" do
          timeoutId = false
          fileName = tRes["File name"]
          if button == "Load" then
            tBlueprint = class.blueprint.copy(data.blueprint)
            tFile.blueprint = nil
            scroll(1,0,0,true,true)
            return
          elseif not fileName then
            button,tRes,reInput = reInput("Invalid file name!")
          elseif fs.exists(fileName..".TAb") then
            button,tRes,reInput = reInput(fileName.." already exists!")
          else
            class.blueprint.save(data.blueprint,fileName)
            input("Successfully saved "..fileName..".TAb.")
            return
          end
        end
      end
    end
  end
}
return common