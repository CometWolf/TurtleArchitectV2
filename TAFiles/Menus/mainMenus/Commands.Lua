local menu
menu = {
  enabled = commands and true,
  [1] = {
    name = "Scan construct...",
    enabled = true,
    help = function()
      window.text"Scans an already built structure and imports it into TA. Block colors will be random."
    end,
    func = function()
      scan()
    end
  },
  [2] = {
    name = "Build blueprint...",
    enabled = true,
    help = function()
      window.text"Begins construction of the currently loaded blueprint, missing build parameters will be requested as well"
    end,
    func = function()
      build(tBlueprint)
    end
  },
  [3] = {
    name = "Remove construct...",
    enabled = true,
    help = function()
      window.text"Uses air instead of blocks to build the loaded blueprint. Mainly used to remove already built structures."
    end,
    func = function()
      build(tBlueprint,true)
    end
  },
}
return menu
