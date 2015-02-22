--The actual glasses table is defined in the settings file, the screen functions are part of the screenBuffer class
glasses.log.open = function(sX,sY,eX,eY)
  glasses.lines = {
    background = glasses.bridge.addBox(sX,eY-1,eX-sX,1,tColors.glass.log,glasses.log.opacity)
  }
  glasses.lines.background.setZ(1)
  for i = eY-10,sY,-10 do
    glasses.lines[#glasses.lines+1] = glasses.bridge.addText(sX+1,i+1," ",tColors.glass.logText)
    local line = glasses.lines[#glasses.lines]
    line.setZ(2)
    line.setAlpha(glasses.log.opacity)
	end
  local file = class.fileTable.new(tFile.settings)
  local line = file:find("  log = { --where to render the message bar",true)
  file:write(
[[    sX = ]]..sX..[[,
    sY = ]]..sY..[[,
    eX = ]]..eX..[[,
    eY = ]]..eY..[[,]],
    line+1
  )
  file:save()
	glasses.lineLength = math.floor((eX-sX)/5)
  glasses.log.refresh()
end

glasses.log.write = function(text,time)
  local timerId = tTimers.display.start()
  local logLine = {text = text,visible = true}
  table.insert(glasses.log,1,logLine)
  glasses.log.timers[tTimers.display.start(time)] = function()
    logLine.visible = false
  end
  glasses.log[glasses.log.maxSize+1] = nil
  if glasses.screenMode:match"Log" then
    glasses.log.refresh()
  end
end

glasses.log.refresh = function()
  local curLine = 1
	local curLog = 1
  while #glasses.lines >= curLine do
    while glasses.log[curLog] and not glasses.log[curLog].visible do
      curLog = curLog+1
    end
    if not glasses.log[curLog] then
      break
    end
	  local text = glasses.log[curLog].text
    if not text then 
      break
    end
    local tLines = string.lineFormat(text,glasses.lineLength)
    for i=#tLines,1,-1 do
      glasses.lines[curLine].setText(tLines[i])
      curLine = curLine+1
      if not glasses.lines[curLine] then
        break
      end
    end
    curLog = curLog+1
  end
  for i=curLine,#glasses.lines do
    glasses.lines[i].setText""
  end
  local background = glasses.lines.background
  local upper = glasses.log.eY-(10*(curLine-1))
  background.setY(upper)
  background.setHeight(glasses.log.eY-upper)
end

glasses.log.setOpacity = function(opacity)
  glasses.lines.background.setOpacity(opacity)
  for i=1,#glasses.lines do
    glasses.lines[i].setAlpha(opacity)
  end
  local file = class.fileTable.new(tFile.settings)
  local line = file:find("    opacity = %d%.?%d?%d?d?, %-%-log transparency")
  file:write("    opacity = "..opacity..", --log transparency",line)
  file:save()
end

glasses.log.close = function()
  glasses.log.lines.background.delete()
	for i=1,#glasses.log.lines do
    glasses.log.lines[i].delete()
	end
	glasses.log.lines = nil
end