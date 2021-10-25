debug = {
  times = 0,
  tExecutionTime = {
    program = os.clock()
  },
  tEventQueue = {},
  prep = function()
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.white)
  end,
  pause = function()
    local tEventQueue = {}
    while true do
      local tEvent = {os.pullEventRaw()}
      if tEvent[1] == "key" then
        if tEvent[2] == keys.backspace then
          error("Quit",0)
        else
          return
        end
      elseif tEvent[1] == "mouse_click"
      or tEvent[1] == "mouse_drag"
      or tEvent[1] == "mouse_scroll" then
        --ignore user input
      else
        debug.tEventQueue[#debug.tEventQueue+1] = tEvent
      end
    end
  end,
  variables = function(...)
    debug.times = debug.times+1
    local tLines = {}
    for i=1,#arg do
      local var = arg[i]
      if not var then
        tLines[#tLines+1] = "nil"
      elseif type(var) == "table" then
        for k,v in pairs(var) do
          tLines[#tLines+1] = k..": "..type(v).." "..tostring(v)
        end
      else
        tLines[#tLines+1] = type(var).." "..tostring(var)
      end
    end
    local lines = tTerm.screen.y-3
    local pages = math.ceil(#tLines/lines)
    for page = 1,pages do
      debug.prep()
      print("Page "..page.."/"..pages.." Debug call #"..debug.times.." on "..tFile.program)
      for line = lines*(page-1)+1,lines*page do
        if not tLines[line] then
          break
        else
          print(tLines[line])
        end
      end
      debug.pause()
    end
    if screen then
      screen:redraw()
    end
    for _i,event in ipairs(debug.tEventQueue) do
      os.queueEvent(unpack(event))
    end
    debug.tEventQueue = {}
    return
  end,
  timedStart = function(key)
    debug.tExecutionTime[k] = os.clock()
  end,
  timedEnd = function(key)
    local endTime = os.clock()
    debug.prep()
    assert(debug.tExecutionTime[key],"Attempt to check non-defined execution time "..key)
    print("Initiated at "..debug.tExecutionTime[key])
    print("Completed at "..endTime)
    print("Total run time: "..endTime-debug.tExecutionTime[key])
    debug.pause()
  end
}
setmetatable(debug,
  {
    __call = function(t,...)
      return debug.variables(...)
    end
  }
)
