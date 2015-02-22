local eventHandler
eventHandler = {
  active = {}, --current event handlers
  switch = function(tHandlers,skipCommon)
    eventHandler.active = {}
    if cTurtle then
       cTurtle.clearEventHandler(true)
    end
    for k,v in pairs(tHandlers) do
      eventHandler.active[k] = (
        eventHandler.common[k]
        and not skipCommon
        and function(tEvent)
          local var1,var2,var3,var4,var5 = eventHandler.common[k](tEvent)
          if var1 then
            return var1,var2,var3,var4,var5
          else
            return v(tEvent)
          end
        end
        or v
      )
      if cTurtle then
        cTurtle.eventHandler[k] = function(tEvent)
          eventHandler.active[k](tEvent)
          screen:refresh()
        end
      end
    end
    if not skipCommon then
      for k,v in pairs(eventHandler.common) do
        eventHandler.active[k] = eventHandler.active[k] or v
        if cTurtle and not cTurtle.eventHandler[k] then
          cTurtle.eventHandler[k] = function(tEvent)
            eventHandler.active[k](tEvent)
            screen:refresh()
          end
        end
      end
    end
  end,
  pull = function(sFilter)
    screen:refresh()
    local tEvent = {os.pullEvent(sFilter)}
    if eventHandler.active[tEvent[1]] then
      return eventHandler.active[tEvent[1]](tEvent)
    end
  end
}
for _k, file in pairs(fs.list(tFile.eventHandlerFolder)) do
  if file ~= "eventHandler.Lua" then
    eventHandler[file:match"(.-)\.Lua"] = loadFile(tFile.eventHandlerFolder.."/"..file)
  end
end
if cTurtle then
  for k,v in pairs(eventHandler.cTurtle) do --load cTurtle specific events
    cTurtle.eventHandler[k] = v
  end
end
return eventHandler
