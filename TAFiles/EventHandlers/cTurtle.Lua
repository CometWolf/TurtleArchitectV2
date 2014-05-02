local cTurtle
cTurtle = { --cTurtle only events
  refuel = function()
    if tMode.sync.amount > 0 then
      rednet.send("Turtle status",{type = "Fuel required",x = cTurtle.tPos.x,y = cTurtle.tPos.y,z = cTurtle.tPos.z})
    end
    local timeOut = tTimers.restockRetry.start()
    input(
      "Fuel required, please put fuel in the currently selected slot and press Ok",
      nil,
      nil,
      {
        timer = function(tEvent)
          if tEvent[2] == timeOut then
            return "Ok"
          end
        end,
        modem_message = function(tEvent)
          if tEvent[3] == modemChannel
          and _G.type(tEvent[5]) == "table"
          and tEvent[5].rID[os.id] then
            local data = tEvent[5]
            if data.event == "Turtle command"
            and data.type == "Refuel" then
              return "Ok"
            end
          end
        end
      }
    )
  end,
  blocked = 0, --amount of times the turtle has been blocked
  moveFail = function() --movement blocked
    cTurtle.blocked = cTurtle.blocked+1
    if cTurtle.blocked%20 == 0
    and tMode.sync.amount > 0 then
      rednet.send(tMode.sync.ids,"Turtle status",{type = "Blocked",x = cTurtle.tPos.x,y = cTurtle.tPos.y,z = cTurtle.tPos.z})
    end
  end
}
return cTurtle