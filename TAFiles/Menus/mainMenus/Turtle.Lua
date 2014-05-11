local menu
menu = {
  enabled = turtle and true,
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
        screen:refresh()
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
}
return menu