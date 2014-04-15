local menu
menu = {
  [1] = {
    name = "Move to...",
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
    name = "Scan layer(WIP)",
    func = function()
      
    end
  },
  [4] = {
    name = "Build blueprint...",
    func = function()
      local button, tRes = input(
        "Input layer range to build",
        {
          "Cancel",
          "Ok"
        },
        {
          {
            name = "Start",
            value = 1,
            accepted = "%d"
          },
          {
            name = "End",
            value = #tBlueprint,
            accepted = "%d"
          }
        }
      )
      if button == "Ok" then
        build(tBlueprint,tRes.Start,tRes.End)
      end
    end
  },
  [5] = {
    name = "Create new...",
    func = function()
      
    end
  },
}
return menu