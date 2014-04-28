local eventHandler
eventHandler = {
  active = {}, --current event handlers
  switch = function(tHandlers,skipCommon)
    eventHandler.active = {}
    if cTurtle then
       cTurtle.clearEventHandler()
    end
    for k,v in pairs(tHandlers) do
      eventHandler.active[k] = (
        eventHandler.common[k]
        and not skipCommon
        and function(tEvent)
          eventHandler.common[k](tEvent)
          return v(tEvent)
        end
        or v
      )
      if cTurtle then
        cTurtle.eventHandler[k] = function(tEvent)
          eventHandler.active[k](tEvent)
        end
      end
    end
    if not skipCommon then
      for k,v in pairs(eventHandler.common) do
        eventHandler.active[k] = eventHandler.active[k] or v
        if cTurtle and not cTurtle.eventHandler[k] then
          cTurtle.eventHandler[k] = function(tEvent)
            eventHandler.active[k](tEvent)
          end
        end
      end
    end
  end,
  pull = function(sFilter)
    screen:refresh()
    local tEvent = {os.pullEvent(sFilter)}
    return eventHandler.active[tEvent[1]] and eventHandler.active[tEvent[1]](tEvent)
  end
}
for _k, file in pairs(fs.list(tFile.eventHandlerFolder)) do
  if file ~= "eventHandler.Lua" then
    eventHandler[file:match"(.-)\.Lua"] = loadFile(tFile.eventHandlerFolder.."/"..file)
  end
end
return eventHandler