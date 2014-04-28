local menu
menu = {
  enabled = function()
    return tMode.sync.amount > 0 and not turtle and true
  end,
  [1] = {
    name = "Move to...",
    enabled = function()
      return tMode.sync.turtles > 0 and true
    end,
    func = function()
      local turtles = ""
      local id
      for k,v in pairs(tMode.sync.ids) do
        if v == "turtle" then
          turtles = turtles..k..","
          if tMode.sync.turtles == 1 then
            id = k
            break
          end
        end
      end
      local button, tRes, reInput = input(
        "Move to coordinates...".."/nTurtle IDs: "..(turtles or ""),
        {
          "Cancel",
          "Ok"
        },
        {
          {
            name = "X",
            value = "",
            accepted = "[-+%d]"
          },
          {
            name = "Y",
            value = "",
            accepted = "[-+%d]"
          },
          {
            name = "Z",
            value = "",
            accepted = "[-+%d]"
          },
          (
            not id and {
              name = "ID",
              value = os.id,
              accepted = "%d"
            } 
            or nil
          )
        },
        false,
        true
      )
      while button ~= "Cancel" do
        local id = tRes.ID or id
        if not tRes.X then
          button,tRes,reInput = reInput"Missing X Coordinate!"
        elseif not tRes.Y then
          button,tRes,reInput = reInput"Missing Y Coordinate!"
        elseif not tRes.Z then
          button,tRes,reInput = reInput"Missing Z Coordinate!"
        elseif not id then
          button,tRes,reInput = reInput"Missing Turtle ID!"
        elseif not tMode.sync.ids[id] then
          button,tRes,reInput = reInput"The ID "..id.." is not connected!"
        elseif tMode.sync.ids[id] ~= "turtle" then
          button,tRes,reInput = reInput"The ID "..id.." is not a turtle!"
        else
          rednet.send(
            id,
            "Turtle command",
            {
              type = "Move",
              x = tRes.X,
              y = tRes.Y,
              z = tRes.Z
            }
          )
          return
        end
      end
    end
  },
  [2] = {
    name = "Turn",
    enabled = function()
      return tMode.sync.turtles > 0 and true
    end,
    func = function()
      local turtles = ""
      local id
      for k,v in pairs(tMode.sync.ids) do
        if v == "turtle" then
          turtles = turtles..k..","
          if tMode.sync.turtles == 1 then
            id = k
            break
          end
        end
      end
      local button, tRes, reInput = input(
        "Turn to.../nTurtle IDs: "..(turtles or ""),
        {
          "Cancel",
          "Ok"
        },
        {
          {
            name = "Direction",
            value = "",
            accepted = "."
          },
          (
            not id and {
              name = "ID",
              value = turtles,
              accepted = "."
            }
            or nil
          )
        },
        false,
        true
      )
      while button ~= "Cancel" do
        local id = tRes.ID or id
        if not tRes.Direction then
          button,tRes,reInput = reInput"Missing turn direction!"
        elseif not cTurtle.dirStandardize(tRes.Direction) then
          button,tRes,reInput = reInput"Invalid turn direction!"
        elseif not id then
          button,tRes,reInput = reInput"Missing turtle ID!"
        elseif not tMode.sync.ids[id] then
          button,tRes,reInput = reInput"The ID "..id.." is not connected!"
        elseif tMode.sync.ids[id] ~= "turtle" then
          button,tRes,reInput = reInput"The ID "..id.." is not a turtle!"
        else
          rednet.send(
            tRes.ID,
            "Turtle command",
            {
              type = "Turn",
              dir = tRes.Direction
            }
          )
          return
        end
      end
    end
  },
  [3] = {
    name = "Build blueprint...",
    enabled = function()
      return tMode.sync.turtles > 0 and true
    end,
    func = function()
      if not dialogue.save"Blueprint must be saved locally prior to building!" then
        input"Construction cancelled"
        return
      end
      local turtles = ""
      local turtleIds = {}
      local turtleAmount = 0
      for id,v in pairs(tMode.sync.ids) do
        if v == "turtle" then
          turtles = turtles..id..","
          if tMode.sync.turtles == 1 then
            turtleIds[id] = true
            turtleAmount = 1
            break
          end
        end
      end
      if turtleAmount < 1 then
        local button, tRes, reInput = input(
          "Input turtle IDs to use for building\nTurtle IDs: "..turtles,
          {
            "Cancel",
            "Ok"
          },
          {
            {
              name = "IDs",
              value = turtles,
              accepted = "[%d,]"
            }
          },
          false,
          true
        )
        while button ~= "Cancel" do
          local ids = {}
          local faultyId = false
          local faultyIds = true
          turtleAmount = 0
          for id in string.gmatch(string.format(tRes["IDs"]),"%d+") do
            id = tonumber(id)
            if not tMode.sync.ids[id] then
              button,tRes,reInput = reInput"The ID("..id..") is not connected"
              faultyId = true
              break
            elseif tMode.sync.ids[id] ~= "turtle" then
              button,tRes,reInput = reInput"The ID("..id..") is not a turtle"
              faultyId = true
              break
            else
              ids[id] = true
              turtleAmount = turtleAmount+1
            end
          end
          if turtleAmount < 1 and not faultyId then
            button,tRes,reInput = reInput"Faulty ID input! Separate IDs with ,"
          elseif not faultyId then
            turtleIds = ids
            break
          end
        end
        if button == "Cancel" then
          return
        end
      end
      local tProgress = checkProgress(tFile.blueprint,false,tBlueprint)
      if not tProgress then
        return
      end
      rednet.send(
        turtleIds,
        "Turtle command",
        {
          type = "Save blueprint progress",
          progress = tProgress,
          blueprintName = tFile.blueprint
        }
      )
      rednet.send(
        turtleIds,
        "Sync edit",
        {
          type = "Colorslots load",
          colorSlots = tBlueprint.colorSlots
        }
      )
      local layers,x,z = tBlueprint:size()
      local xChunks = math.ceil(x/turtleAmount)
      local xNext = 0
      for id in pairs(turtleIds) do
        rednet.send(
          id,
          "Sync edit",
          {
            type = "Blueprint sub",
            sX = xNext+1,
            sZ = 1,
            eX = xNext+xChunks,
            eZ = z,
          }
        )
        xNext = xNext+xChunks
      end
      rednet.send(turtleIds,"Turtle command",{type = "Build"}
      )
    end
  }
}
return menu