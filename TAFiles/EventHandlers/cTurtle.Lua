local handler
local tSlots = {}
for i=1,16 do
  tSlots[i] = "Slot "..i
end
handler = { --cTurtle only events
  refuel = function()
    if tMode.sync.amount > 0 then
      rednet.send(tMode.sync.ids,"Turtle status",{type = "Fuel required",x = cTurtle.tPos.x,y = cTurtle.tPos.y,z = cTurtle.tPos.z})
    end
    tTimers.restockRetry.start()
    local button,slot = window.scroll(
      "Fuel required, please select slot to refuel from and press Ok",
      tSlots,
      false,
      {
        timer = function(tEvent)
          if tTimers.restockRetry.ids[tEvent[2]] then
            return "timeout"
          end
        end,
        modem_message = function(tEvent)
          if tEvent[3] == modemChannel
          and _G.type(tEvent[5]) == "table"
          and tEvent[5].rID[os.id] then
            local data = tEvent[5]
            if data.event == "Turtle command"
            and data.type == "Refuel" then
              return "timeout"
            end
          end
        end
      },
      true
    )
    while button ~= "timeout" do
      turtle.select(tonumber(slot:match"%d+"))
      turtle.refuel(64)
      return true
    end
  end,
  blocked = 0, --amount of times the turtle has been blocked
  moveFail = function() --movement blocked
    handler.blocked = handler.blocked+1
    if handler.blocked > 10
    and tMode.sync.amount > 0 then
      handler.blocked = 0
      rednet.send(tMode.sync.ids,"Turtle status",{type = "Blocked",x = cTurtle.tPos.x,y = cTurtle.tPos.y,z = cTurtle.tPos.z})
    end
  end
}
return cTurtle
