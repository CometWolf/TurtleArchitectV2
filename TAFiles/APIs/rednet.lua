rednet = setmetatable(
  {
    send = function(rID,event,content,success,timeout,time,failure)
      content = content or {}
      content.rID = type(rID) == "table" and rID or {[rID] = true}
      content.sID = os.id
      content.event = event
      -- Fields used by repeaters
      content.nMessageID = math.random( 1, 2147483647 )
      content.nRecipient = modemChannel
      -- End Fields used by repeaters
      local clear
      for id in pairs(content.rID) do
        local timerId
        if timeout then
          timerId = tTimers.modemRes.start(time) --if not time, the default modemRes time is used
          clear = function(rID,tID)
            tTimers.modemRes.ids[tID] = nil
            tTransmissions.failure.timeout[tID] = nil
            tTransmissions.failure[event][rID] = nil
            tTransmissions.success[event][rID] = nil
          end
          tTransmissions.failure.timeout[timerId] = function()
            clear(id,timerId)
            timeout(id)
          end
        end
        clear = clear or function(rID) --different clear if there is no timeout function
          tTransmissions.failure[event][rID] = nil
          tTransmissions.success[event][rID] = nil
        end
        tTransmissions.success[event][id] = (
          success 
          and function(data)
            clear(id,timerId)
            success(id,data)
          end
          or function() 
            clear(id,timerId)
          end
        )
        tTransmissions.failure[event][rID] = (
          failure
          and function()
            clear(id,timerId)
            failure(id)
          end
          or clear
        )
      end
      modem.transmit(
        modemChannel,
        modemChannel,
        content
      )
      modem.transmit( -- Also transmit on the repeater channel
        65533,
        modemChannel,
        content
      )
    end,
    connected = { --connected computers
      amount = 0,
      ids = {
        
      }
    },
    connect = function(id,type,time,success)
      rednet.send(
        id,
        "Init connection",
        {
          type = type,
          turtle = turtle and true
        },
        function(id,data)
          rednet.connected.ids[id] = true
          rednet.connected.amount = rednet.connected.amount+1
          --tTimers.connectionPing.start()
          if success then
            success(id,data)
          end
        end,
        function(id)
          window.text("Failed to connect to computer ID "..id..".")
        end,
        time,
        function(id)
          window.text("Computer ID "..id.." denied your connection request")
        end
      )
    end,
    disconnect = function(ids)
      ids = type(ids) == "table" and ids or {[ids] = true}
      rednet.send(ids,"Close connection")
      local idsLoop = {}
      for id in pairs(ids) do
        idsLoop[#idsLoop+1] = id
      end
      for i = 1,#idsLoop do
        local id = idsLoop[i]
        rednet.connected.ids[id] = nil
        rednet.connected.amount = rednet.connected.amount-1
        if tMode.sync.ids[id] then
          tMode.sync.turtles = tMode.sync.ids[id] == "turtle" and tMode.sync.turtles-1 or tMode.sync.turtles
          tMode.sync.ids[id] = nil
          tMode.sync.amount = tMode.sync.amount-1
        end
      end
    end
  },
  {
  __index = _G.rednet
  }
)