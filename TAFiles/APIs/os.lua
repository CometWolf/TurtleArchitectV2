os = setmetatable(
  {
    sleepTimer = {},
    sleep = function(time)
      local sleeping = true
      os.sleepTimer[os.startTimer(time)] = function()
        sleeping = false
      end
      while sleeping do
        eventHandler.pull()
      end
    end,
    id = _G.os.getComputerID()
  },
  {
    __index = _G.os
  }
)