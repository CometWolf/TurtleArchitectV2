local menu
menu = {
  enabled = turtle and true,
  [1] = {
    name = "Move to...",
    enabled = true,
    help = function()
      window.text"Moves the turtle to the given coordinates"
    end,
    func = function()
      local button, tRes = window.text(
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
    help = function()
      window.text"Turns the turtle in the given direction. Supports most forms of direction input like x+, north, right"
    end,
    func = function()
      local button, tRes = window.text(
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
    help = function()
      window.text"Begins construction of the currently loaded blueprint, missing build parameters will be requested as well"
    end,
    func = function()
      build(tBlueprint)
    end
  },
}
return menu
