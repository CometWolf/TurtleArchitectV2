local menu
menu = {
  enabled = commands and true,
  [1] = {
    name = "Move construct...",
    enabled = false,
    help = function()
      window.text"Moves an already constructed blueprint to the specified coordinates"
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
    name = "Scan construct...",
    enabled = false,
    help = function()
      window.text"Scans an already built structure and imports it into TA. Block colors will be random."
    end,
    func = function()
      
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
