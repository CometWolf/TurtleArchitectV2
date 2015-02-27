local menu
menu = {
  enabled = function()
    return tMode.sync.amount > 0 and not turtle and true
  end,
  [1] = {
    name = "Move to...",
    enabled = function()
      return tMode.sync.turtles > 0
    end,
    help = function()
      window.text"Move a synced turtle to the given coordinates"
    end,
    func = function()
      local id,nID = dialogue.selectTurtle("Select turtle ID to move")
      if not id then
        return
      end
      local button,tRes,reInput = window.text(
        "Move turtle "..nID.." to coordinates...",
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
          }
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
    help = function()
      window.text"Turn a synced turtle in the given direction. Most forms of directions are supported, like x+,north or right"
    end,
    func = function()
      local id,nID = dialogue.selectTurtle("Select turtle ID to turn")
      if not id then
        return
      end
      local button, tRes, reInput = window.text(
        "Turn turtle "..nID.."...",
        {
          "Cancel",
          "Ok"
        },
        {
          {
            name = "Direction",
            value = "",
            accepted = "."
          }
        },
        false,
        true
      )
      while button ~= "Cancel" do
        if not tRes.Direction then
          button,tRes,reInput = reInput"Missing turn direction!"
        else
          rednet.send(
            id,
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
    help = function()
      window.text"Makes synced turtles build the currently loaded blueprint"
    end,
    func = function()
      if not dialogue.save"Blueprint must be saved locally prior to building!" then
        window.text"Construction cancelled"
        return
      end
      local ids, turtleAmount = dialogue.selectTurtle("Select turtle IDs to use for building",true)
      if not ids then
        return
      end
      local tProgress = checkProgress(tFile.blueprint,false,tBlueprint)
      if not tProgress then
        return
      end
      local button = window.text(
        "Enable auto resume?",
        {
          "Cancel",
          "Ok"
        }
      )
      local autoRecovery = button == "Ok"
      rednet.send(
        ids,
        "Turtle command",
        {
          type = "Save blueprint progress",
          progress = tProgress,
          blueprintName = tFile.blueprint
        }
      )
      rednet.send(
        ids,
        "Sync edit",
        {
          type = "Colorslots load",
          colorSlots = tBlueprint.colorSlots
        }
      )
      local layers,x,z = tBlueprint:size()
      local xChunks = math.ceil(x/turtleAmount)
      local xNext = 0
      for id in pairs(ids) do
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
      rednet.send(ids,"Turtle command",{type = "Build", auto = autoRecovery})
    end
  }
}
return menu
