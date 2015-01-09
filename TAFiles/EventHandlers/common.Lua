local common
common = { --common event handlers, these are always active
  turtle_response = function(tEvent)
    os.queueEvent(unpack(tEvent))
    return true
  end,
  timer = function(tEvent)
    local timerID = tEvent[2]
    if timerID == tTimers.blink.id then
      local toggle = tTimers.blink.toggle
      tTimers.blink.toggle = not toggle
      if toggle then
        renderToolOverlay()
      else
        screen:clearLayer(screen.layers.toolsOverlay)
      end
      tTimers.blink.start()
      return true
    elseif timerID == tTimers.ctrl.id then
      tTimers.ctrl.lPressed = false
      tTimers.ctrl.rPressed = false
      return true
    elseif timerID == tTimers.shift.id then
      tTimers.shift.pressed = false
      return true
    elseif tTimers.display.ids[timerID] then
      local func = glasses.log.timers[timerID]
      if func then
        func()
        if glasses.screenMode:match"Log" then
          glasses.log.refresh()
        end
      end
      return true
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
            window.text("Connection to computer ID "..id.." was lost.")
          end
        )
      end
      tTimers.connectionPing.start()
      return true
    elseif tTimers.modemRes.ids[timerID] then
      local func = tTransmissions.failure.timeout[timerID]
      if func then
        return func()
      end
      return true
    elseif os.sleepTimer[timerID] then
      os.sleepTimer[timerID]()
      return true
    end
  end,
  peripheral = function(tEvent)
    local side = tEvent[2]
    if not modem and peripheral.getType(side) == "modem" and peripheral.call(side,"isWireless") then
      modem = peripheral.wrap(side)
      modem.open(modemChannel)
      modem.side = side
      return true
    elseif not glasses and peripheral.getType(side) == "openperipheral_glassesbridge" then
      glasses.bridge = peripheral.wrap(side)
      glasses.side = side
      if glasses.screenMode:match"Screen" then
        screen:glassInit(glasses.bridge,glasses.screen.size.x,glasses.screen.size.y,glasses.screen.pos.x,glasses.screen.pos.y)
      end
      if glasses.screenMode:match"Log" then
			  glasses.log.open(glasses.log.sX,glasses.log.sY,glasses.log.eX,glasses.log.eY)
      end
      return true
    end
  end,
  peripheral_detach = function(tEvent)
    local side = tEvent[2]
    if modem and side == modem.side then
      modem = nil
      return true
    elseif glasses.bridge and side == glasses.side then
      glasses.log.close()
      screen:glassClose()
      glasses.bridge = nil
      return true
    end
  end,
  term_resize = function()
    tTerm.screen.x,tTerm.screen.y = term.getSize()
    tTerm.screen.xMid = math.floor(tTerm.screen.x/2) --middle of the screen sideways
    tTerm.screen.yMid = math.floor(tTerm.screen.y/2) --middle of the screen up and down
    tTerm.canvas.sX = 1 --canvas left side
    tTerm.canvas.eX = tTerm.screen.x-2 --canvas edge
    tTerm.canvas.tX = tTerm.canvas.eX-tTerm.canvas.sX+1 --canvas total length
    tTerm.canvas.sZ = 1 --canvas top side
    tTerm.canvas.eZ = tTerm.screen.y-1 --canvas bottom
    tTerm.canvas.tZ = tTerm.canvas.eZ-tTerm.canvas.sZ+1 --canvas total height
    tTerm.viewable.sX = 1 --left side of the blueprint in view
    tTerm.viewable.eX = tTerm.canvas.eX --edge of the blueprint in view
    tTerm.viewable.sZ = 1 --top side of the blueprint in view
    tTerm.viewable.eZ = tTerm.canvas.eZ --bottom of the blueprint in view
    tTerm.viewable.mX = 0 --view modifier sideways
    tTerm.viewable.mZ = 0 --view modifier up or down
    tTerm.scroll.x = 0 --canvas scroll sideways
    tTerm.scroll.z = 0 --canvas scroll up or down
    tTerm.scroll.layer = 1 --currently in view layer
    while rawget(screen,1) do
      screen:delLayer(1)
    end
    eventHandler.switch(eventHandler.main)
    renderBottomBar()
    renderSideBar()
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
    if tCommand[1] == "resize"
    or tCommand[1] == "repos" then
      local x,y,command
      if type(tCommand[2]) == "number" and type(tCommand[3]) == "number" then
        command = glasses.screenMode:match"^%S+$"
        command = command and command:lower()
        x1 = tCommand[2]
        y1 = tCommand[3]
        x2 = tCommand[4]
        y2 = tCommand[5]
      elseif type(tCommand[2]) == "string" then
        command = tCommand[2]
        x1 = tCommand[3]
        y1 = tCommand[4]
        x2 = tCommand[5]
        y2 = tCommand[6]
      end
      if tCommand[1] == "resize" then
        if type(x1) == "number" and type(y1) == "number" then
          screen:glassResize(x1,y1)
        end
      elseif tCommand[1] == "repos" then
        if command == "screen" then
          if type(x1) == "number" and type(y1) == "number" then
            screen:glassInit(x1,y1,glasses.screen.size.x,glasses.screen.size.y)
          end
        elseif command == "log" then
          if type(x1) == "number" and type(y1) == "number" and type(x2) == "number" and type(y2) == "number" then
            glasses.log.close()
            glasses.log.open(x1,y1,x2,y2)
          end
        end
      end
    elseif tCommand[1] == "opacity" then
      local opacity,command
      if type(tCommand[2]) == "number" then
        command = glasses.screenMode:match"^%S+$"
        command = command and command:lower()
        opacity = tCommand[2]
      else
        command = tCommand[2]
        opacity = tCommand[3]
      end
      if type(opacity) == "number" then
        if command == "screen" then
          screen:glassOpacity(opacity)
        elseif command == "log" then
          glasses.log.setOpacity(opacity)
        end
      end
    elseif tCommand[1] == "mode" then
      local screenMode = command:match"screen" and true
      local logMode = command:match"log" and true
      local oldScreenMode = glasses.screenMode:match"Screen" and true
      local oldLogMode = glasses.screenMode:match"Log" and true
      if screenMode or logMode then
        glasses.screenMode = (screenMode and "Screen " or "")..(logMode and "Log" or "")
        local file = class.fileTable.new(tFile.settings)
        local line = file:find('  screenMode = ".+", %-%-glasses display mode')
        file:write('  screenMode = "'..glasses.screenMode..'", --glasses display mode,simply write which modes you want in plain text, remember to capitalize the first letter',line)
        file:save()
        if not oldScreenMode and screenMode then
          screen:glassInit(glasses.screen.size.x,glasses.screen.size.y,glasses.screen.pos.x,glasses.screen.pos.y)
        elseif not screenMode and oldScreenMode then
          screen:glassClose()
        end
        if not oldLogMode and logMode then
          glasses.log.open(glasses.log.sX,glasses.log.sY,glasses.log.eX,glasses.log.eY)
        elseif not logMode and oldLogMode then
          glasses.log.close()
        end
      end
    elseif tCommand[1] == "toggle" then
      if tCommand[2] == "follow" and tCommand[3] == "turtle" then
        glasses.followTurtle = not glasses.followTurtle
      end
    elseif tCommand[1] == "test" then
      glasses.log.write(table.concat(tCommand," ",2))
    elseif tMenu.main[menuName] and not inputOpen then
      if not tCommand[2] and not tMenu.open then
        renderMenu(menuName)
      else
        local funcName = table.concat(tCommand," ",(tCommand[2] and 2 or 1))
        funcName = string.upper(string.sub(funcName,1,1))..string.sub(funcName,2)
        for i=1,#tMenu.main[menuName].items do
          if tMenu.main[menuName].items[i].name:match(funcName) then
            renderMenu()
            tMenu.main[menuName].items[i].func()
          end
        end
      end
    elseif tMenu.open and not inputOpen then
      menuName = tMenu.open
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
    and (tEvent[5].rID[os.id] or tEvent[5].rID.All) then
      local data = tEvent[5]
      local event = data.event
      local senderId = data.sID
      local type = data.type
      if event == "Success" then
        local func = tTransmissions.success[type][senderId]
        if func then
          func(data)
          return true
        end
      elseif event == "Failure" then
        local func = tTransmissions.failure[type][senderId]
        if func then
          func(data)
          return true
        end
      elseif event == "Ping" then
        rednet.send(senderId,"Success",{type="Ping",turtle = turtle and true or nil})
      elseif event == "Init connection" then
        if type == "Sync" then
          --[[local timeoutId = tTimers.inputTimeout.start()
          local button = window.text(
            "Computer ID "..senderId.." wants to initiate sync mode.",
            {
              "Deny",
              "Accept"
            },
            false,
            {
              timer = function(tEvent)
                if tEvent[2] == timeoutId then
                  return "Deny"
                end
              end
            }
          )
          if button == "Accept" or "Ok" then]]--
            if not tMode.sync.ids[senderId] then 
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
            end
            rednet.send(senderId,"Success",{type = event,turtle = turtle and true})
          --else
          --  rednet.send(senderId,"Failure",{type = event})
          --end
          return true
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
          if data.layer then
            tBlueprint[data.layer]:paste(data.l,data.sX,data.sZ,data.merge)
          else
            tBlueprint:paste(data.l,data.sX,data.sZ,data.merge)
          end
          if data.eX and data.eZ then
            renderArea(data.sX,data.sZ,data.eX,data.eZ,true)
          else
            scroll()
          end
        elseif type == "Point" then --probably brush
          tBlueprint[data.layer][data.x][data.z] = data.color
          if tTerm.scroll.layer == data.layer then
            renderPoint(data.x,data.z,true)
          end
					if data.isBuilding then
					  glasses.log.write("Turtle "..senderId.." "..(data.color and "placed "..keyColor[data.color].." at" or "broke").."\n"..data.x..", "..data.layer..", "..data.z)
            if glasses.bridge and glasses.followTurtle then
              scroll(data.layer,data.x-math.floor(tTerm.canvas.tX/2),data.z-math.floor(tTerm.canvas.tZ/2),true,true)
            end
					end
        elseif type == "Delete" then
          for iX = data.sX,data.eX do
            for iZ = data.sZ,data.eZ do
              tBlueprint[data.layer][iX][iZ] = nil
            end
          end
          renderArea(data.sX,data.sZ,data.eX,data.eZ,true)
        elseif type == "Recolor" then
          if data.layers then
            for layer in pairs(data.layers) do
              tBlueprint[data.layer]:recolor(data.color,data.sX,data.sZ,data.eX,data.eZ)
            end
            if data.layers[tTerm.scroll.layer] then
              renderArea(data.sX,data.sZ,data.eX,data.eZ)
            end
          else
            tBlueprint[data.layer]:recolor(data.color,data.sX,data.sZ,data.eX,data.eZ)
            if tTerm.scroll.layer == data.layer then
              renderArea(data.sX,data.sZ,data.eX,data.eZ)
            end
          end
        elseif type == "Mark built" then
          if data.blueprint then
            tBlueprint:markBuilt(nil,nil,nil,nil,data.clearBreak)
            if tMode.renderBuilt then
              renderArea(data.sX,data.sZ,data.eX,data.eZ)
            end
          elseif data.layer then
            tBlueprint[data.layer]:markBuilt(data.sX,data.sZ,data.eX,data.eZ)
            if tMode.renderBuilt and data.layer == tTerm.scroll.layer then
              renderArea(data.sX,data.sZ,data.eX,data.eZ,data.clearBreak)
            end
          elseif data.layers then
            for layer in pairs(data.layers) do
              tBlueprint[layer]:markBuilt(data.sX,data.sZ,data.eX,data.eZ,data.clearBreak)
            end
            if (tMode.renderBuilt or data.clearBreak) and data.layers[tTerm.scroll.layer] then
              renderArea(data.sX,data.sZ,data.eX,data.eZ)
            end
          end
        elseif type == "Mark unbuilt" then
          if data.blueprint then
            tBlueprint:markUnbuilt()
            if tMode.renderBuilt then
              renderArea(data.sX,data.sZ,data.eX,data.eZ)
            end
          elseif data.layer then
            tBlueprint[data.layer]:markUnbuilt(data.sX,data.sZ,data.eX,data.eZ)
            if tMode.renderBuilt and data.layer == tTerm.scroll.layer then
              renderArea(data.sX,data.sZ,data.eX,data.eZ)
            end
          elseif data.layers then
            for layer in pairs(data.layers) do
              tBlueprint[layer]:markUnbuilt(data.sX,data.sZ,data.eX,data.eZ)
            end
            if tMode.renderBuilt and data.layers[tTerm.scroll.layer] then
              renderArea(data.sX,data.sZ,data.eX,data.eZ)
            end
          end
        elseif type == "Layer add" then
          while #tBlueprint < data.layer do
            tBlueprint[#tBlueprint+1] = class.layer.new()
          end
          if tMode.layerBar then
            renderLayerBar(true)
          end
        elseif type == "Layer delete" then
          if data.layers then
            local delLayers = {}
            for layer in pairs(data.layers) do
              delLayers[#delLayers+1] = layer
            end
            table.sort(
              delLayers,
              function(k1,k2)
                return k1 < k2
              end
            )
            for i,layer in ipairs(delLayers) do
              if layer == 1 and #tBlueprint == 1 then
                tBlueprint[1] = tBlueprint[1].new()
              else
                table.remove(tBlueprint,i)
              end
            end
            scroll()
            if tMode.layerBar then
              renderLayerBar(true)
            end
            return
          elseif data.layer then
            data.from = data.layer
            data.to = data.layer
          end
          for layer=data.to,data.from,-1 do
            if layer == 1 and #tBlueprint == 1 then
              tBlueprint[1] = tBlueprint[1].new()
            else
              table.remove(tBlueprint,layer)
            end
          end
          scroll()
          if tMode.layerBar then
            renderLayerBar(true)
          end
        elseif type == "Layer clear" then
          if data.layers then
            for layer in pairs(data.layers) do
              tBlueprint[layer] = class.layer.new()
            end
            if data.layers[tTerm.scroll.layer] then
              scroll()
            end
            return
          elseif data.layer then
            data.from = data.layer
            data.to = data.layer
          end
          for layer=data.from,data.to do
            tBlueprint[layer] = class.layer.new()
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
          if tMode.layerBar then
            renderLayerBar(true)
          end
        elseif type == "Blueprint sub" then
          tBlueprint = tBlueprint:copy(data.sX,data.sZ,data.eX,data.eZ)
          tBlueprint:save(tFile.blueprint,true)
          for i=1,#tBlueprint do
            scroll(i,0,0,true) --i don't fucking know anymore, I GIVE UP
          end
          scroll(1,0,0,true,true)
        elseif type == "Colorslots load" then
          tBlueprint.colorsSlots = class.matrix.new(2,data.colorSlots)
          tBlueprint:save(tFile.blueprint,true)
        end
        return true
      elseif event == "Sync OFF"
      or event == "Close connection" then
        if tMode.sync.ids[senderId] then
          local turtle = tMode.sync.ids[senderId] == "turtle"
          tMode.sync.turtles = tMode.sync.turtles-(turtle and 1 or 0)
          tMode.sync.amount = tMode.sync.amount-1
          tMode.sync.ids[senderId] = nil
          if turtle and tMode.sync.turtles == 0 then
            renderSideBar()
          end
          window.text((turtle and "Turtle" or "Computer").." ID "..senderId.." has de-synced")
        end
        if rednet.connected.ids[senderId] then
          rednet.connected.ids[senderId] = nil
          rednet.connected.amount = rednet.connected.amount-1
        end
        return true
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
          tFile.blueprint = data.blueprintName
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
        return true
      elseif event == "Turtle status" and not tIgnore[senderId] then
        if type == "Build complete" then
				  window.text("Turtle "..senderId.." has completed construction of "..data.blueprintName)
          return true
				elseif type == "Layer complete" then
					glasses.log.write("Turtle "..senderId.." completed layer "..data.layer.." of "..data.blueprintName)
          return true
        elseif type == "Blocked" then
          glasses.log.write("Turtle "..senderId.." is being blocked, please remove the obstruction at\nX: "..data.x.."\nY: "..data.y.."n\Z: "..data.z)
          return true
				elseif type == "Blocks required" then
          local timeOut = tTimers.restockRetry.start()
          local button = window.text(
            "Turtle "..senderId.." requires more "..keyColor[data.color].." blocks in the slots "..data.slots.." to continue building",
            {
              "Cancel",
              "Ignore",
              "Ok"
            },
            false,
            {
              modem_message = function(tEvent)
                if tEvent[3] == modemChannel
                and _G.type(tEvent[5]) == "table"
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
              end,
              timer = function(tEvent)
                if tTimers.restockRetry[tEvent[2]] then
                  return "Cancel"
                end
              end
            }
          )
          if button == "Ok" then
            rednet.send(senderId,"Turtle command",{type == "Restock"})
          elseif button == "Ignore" then
            tIgnore[senderId] = true
          end
          return true
				elseif type == "Fuel required" then
          local timeOut = tTimers.restockRetry.start()
          local button = window.text(
            "Turtle "..senderId.." located at\nX: "..data.x.."\nY: "..data.y.."\nZ: "..data.z.."\nrequires fuel",
            {
              "Cancel",
              "Ignore",
              "Ok"
            },
            false,
            {
              modem_message = function(tEvent)
                if tEvent[3] == modemChannel
                and _G.type(tEvent[5]) == "table"
                and tEvent[5].rID[os.id] then
                  local data = tEvent[5]
                  local event = data.event
                  local senderId2 = data.sID
                  local type = data.type
                  if event == "Turtle status"
                  and type == "Refuel" 
                  and senderId == senderId2 then
                    return "Cancel"
                  end
                end
              end,
              timer = function(tEvent)
                if tTimers.restockRetry[tEvent[2]] then
                  return "Cancel"
                end
              end
            }
          )
          if button == "Ok" then
            rednet.send(senderId,"Turtle command",{type == "Refuel"})
          elseif button == "Ignore" then
            tIgnore[senderId] = true
          end
        end
        return true
      elseif event == "Blueprint transmission" then
        local timeoutId = tTimers.inputTimeout.start()
        local button, tRes, reInput = window.text(
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
            button,tRes,reInput = reInput"Invalid file name!"
          elseif fs.exists(fileName..".TAb") then
            button,tRes,reInput = reInput(fileName.." already exists!")
          else
            class.blueprint.save(data.blueprint,fileName)
            window.text("Successfully saved "..fileName..".TAb.")
            return
          end
        end
        return true
      end
    end
  end,
}
return common