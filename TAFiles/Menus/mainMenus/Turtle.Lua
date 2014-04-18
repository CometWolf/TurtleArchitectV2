local menu
menu = {
  [1] = {
    name = "Move to...",
    enabled = true,
    func = function()
      local button, tRes = input(
        "Move to coordinates...",
        {
          "Cancel",
          "Ok"
        },
        {
          {
            name = "X",
            value = cTurtle.tPos.x,
            accepted = "[-+%d]"
          },
          {
            name = "Y",
            value = cTurtle.tPos.y,
            accepted = "[-+%d]"
          },
          {
            name = "Z",
            value = cTurtle.tPos.z,
            accepted = "[-+%d]"
          },
        }
      )
      if button == "Ok" then
        cTurtle.moveToXYZ(tRes.X,tRes.Y,tRes.Z)
      end
    end
  },
  [2] = {
    name = "Turn",
    enabled = true,
    func = function()
      local button, tRes = input(
        "Turn to...",
        {
          "Cancel",
          "Ok"
        },
        {
          {
            name = "Direction",
            value = cTurtle.tPos.dir,
            accepted = "."
          },
        }
      )
    end
  },
  [3] = {
    name = "Build blueprint...",
    enabled = true,
    func = function()
      build(tBlueprint)
    end
  },
  [4] = {
    name = "Break mode",
    enabled = true,
    func = function()
      local button = input(
        [[Break mode means the turtle will break any obstructions in it's path, provided it has a pickaxe.
Break mode: ]]..tOngoing.breakMode and "ON" or "OFF",
        {
          "Cancel",
          (tOngoing.breakMode and "Break mode OFF" or "Break mode ON"),
        }
      )
      if button == "Break mode ON" then
        tOngoing.breakMode = true
      elseif button == "Break mode OFF" then
        tOngoing.breakMode = false
      end
    end
  },
}
return menu