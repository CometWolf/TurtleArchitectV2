--[[----------------------------------------------------------------------------------------------------------
Input functions
----------------------------------------------------------------------------------------------------------]]--
local activeInputs = 0 --amount of windows open
inputOpen = false --whether an input window is currently open or not
local inputDefaults = { --default values for tInputFields tables passed to the input function
  name = "", --text on the side of the field
  accepted = ".", --accepted input pattern
  value = "", --value already inputted
  charLimit = math.huge, --amount of characters allowed
  backgroundColor = tColors.inputBar,
  textColor = tColors.inputText,
  nameColor = tColors.inputBoxText
}
local animationDefaults = { --default animation values for animated text
  text = "",
  bColor = tColors.inputBox, --backgroundColor
  tColor = tColors.inputBoxText, --textColor
  renderTime = 1 --time before next frame
}
local scrollDefaults = { --default values for scroll selections
  text = "",
  sText = tColors.scrollBoxSelectText, --selected text color
  sBackground = tColors.scrollBoxSelected, --selected text background color
  uText = tColors.scrollBoxSelectText, --unselected text color
  uBackground = tColors.scrollBoxUnselected, --unselected text background color
  selected = false --selected by default
}
window = {
  text = function(text,tButtonFields,tInputFields,customEvent,reInput)
    local screenLayer = screen.layers.dialogue+activeInputs
    inputOpen = true
    screen:setLayer(screenLayer)
    activeInputs = activeInputs+1
    tInputFields = tInputFields or {}
    --set up text
    local lineLength = tTerm.screen.x-2 --max line length
    local animated = false
    local textColor
    local maxLines = tTerm.screen.y-3-#tInputFields
    if type(text) == "table" then
      if type(text[1]) == "table" then --animation
        animated = true
        text.activeFrame = 1
        for i,frame in ipairs(text) do
          setmetatable(frame,{__index = animationDefaults})
          frame.lines = string.lineFormat(frame.text,lineLength,true)
        end
      else --plain text
        text = {
          lines = string.lineFormat(table.concat(text,"\n"),lineLength,true),
          tColor = text.tColor or tColors.inputBoxText,
          bColor = text.bColor or tColors.inputBox
        }
      end
    else--converts to table if it's not a table
      text = {
        lines = string.lineFormat(text,lineLength,true),
        tColor = tColors.inputBoxText,
        bColor = tColors.inputBox
      }
    end
    local tLine = ""
    if animated then 
      for i,frame in ipairs(text) do
        if #frame.lines > #tLine then
          tLine = frame.lines
          tLine.text = frame.text
        end
      end
      if #tLine > maxLines then
        error("Screen too small for animation",2)
      end
      glasses.log.write(tLine.text)
    else
      tLine = text.lines
      if #tLine > maxLines then
        local windowLines = {}
        for i=#tLine-maxLines+1,#tLine do
          windowLines[#windowLines+1] = tLine[i]
          tLine[i] = nil
        end
        window.text(table.concat(tLine),{"Ok"}) --omg recursion
        screen:setLayer(screenLayer)
        tLine = windowLines
      end
    end
    --default input fields
    local tInputs = {}
    for i=1,#tInputFields do
      if type(tInputFields[i]) ~= "table" then
        tInputs[i] = {
          name = tInputFields[i]
        }
        tInputFields[i] = {
          name = tInputFields[i]
        }
      else
        tInputs[i] = {}
        for k,v in pairs(tInputFields[i]) do
          tInputs[i][k] = v
        end
      end
      local field = tInputs[i]
      if field.value and type(field.value) == "number" then
        field.value = string.format(field.value)
      end
      setmetatable(field,
        {
          __index = inputDefaults
        }
      )
    end
    --default buttons
    local tButtons = {}
    if type(tButtonFields) == "string" then
      tButtons = {
        [1] = tButtonFields
      }
    elseif not tButtonFields or #tButtonFields < 1 then
      tButtons = {
        [1] = "Ok"
      }
    else
      for k,v in pairs(tButtonFields) do
        tButtons[k] = v
      end
    end
    local oldHandlers = eventHandler.active--stores currently in use event handlers, prior to switch
    local eventQueue = {} --unrelated events which occurred during the dialogue
    local prevBlink = screen:getBlink()
    screen:setCursorBlink(false)
    local function endExecution(event)
      --closes input box and returns event and the values in the input fields
      eventHandler.switch(oldHandlers,true)
      local tRes = {}
      for iR=1,#tInputs do
        tRes[tInputs[iR].name] = tInputs[iR].value ~= "-" and tonumber(tInputs[iR].value) or #tInputs[iR].value > 0 and tInputs[iR].value
      end
      screen:setCursorBlink(false)
      if reInput then
        for i=1,#tInputFields do
          for k,v in pairs(tRes) do
            if k == tInputFields[i].name then
              tInputFields[i].value = v
              break
            end
          end
        end
        reInput = function(reText) --set up reInput function
          return window.text(reText,tButtonFields,tInputFields,customEvent,true)
        end
      end
      screen:setCursorBlink(prevBlink)
      screen:delLayer(screenLayer)
      inputOpen = (screenLayer ~= screen.layers.dialogue)
      activeInputs = activeInputs-1
      for i=1,#eventQueue do
        os.queueEvent(unpack(eventQueue[i]))
      end
      return event,tRes,reInput
    end
    --render box
    local box = {
      height = #tLine+2+#tInputs,
      width = tTerm.screen.x-2
    }
    box.top = math.ceil(tTerm.screen.yMid-(box.height/2))
    box.bottom = box.height+box.top
    if box.top < 1 then
      box.bottom = box.bottom+(1-box.top)
      box.top = 1
    end
    screen:drawBox(2,box.top,tTerm.screen.x-1,box.bottom,tColors.inputBox)
    screen:drawFrame(1,box.top,tTerm.screen.x,box.bottom,tColors.inputBoxBorder)
    --write text
    screen:setBackgroundColor(tColors.inputBox)
    screen:setTextColor(tColors.inputBoxText)
    for i,line in ipairs(tLine) do
      screen:setCursorPos(2,box.top+i)
      screen:write(line)
    end
    --set up & render buttons
    local totalButtonSpace = 0
    local buttonTouchMap = class.matrix.new(2)
    for i=1,#tButtons do
      tButtons[i] = {
        name = tButtons[i]
      }
      tButtons[i].size = #tButtons[i].name+2
      totalButtonSpace = totalButtonSpace+tButtons[i].size+2
    end
    local nextButton = math.ceil(tTerm.screen.xMid-(totalButtonSpace/2)+2)
    screen:setTextColor(tColors.inputButtonText)
    screen:setBackgroundColor(tColors.inputButton)
    for i=1,#tButtons do
      tButtons[i].sX = nextButton
      tButtons[i].eX = nextButton+tButtons[i].size-1
      tButtons[i].y = box.bottom-1
      screen:setCursorPos(tButtons[i].sX,tButtons[i].y)
      screen:write(" "..tButtons[i].name.." ")  --add spaces for appearances
      for iX=tButtons[i].sX,tButtons[i].eX do
        buttonTouchMap[iX][tButtons[i].y] = tButtons[i].name
      end
      nextButton = nextButton+#tButtons[i].name+3
    end
    --set up & render input boxes
    local inputTouchMap = class.matrix.new(2)
    if #tInputs > 0 then
      for i=#tInputs,1,-1 do
        local field = tInputs[i]
        screen:setBackgroundColor(tColors.inputBox)
        screen:setTextColor(field.nameColor)
        screen:setCursorPos(3,box.bottom-2-#tInputs+i)
        screen:write(field.name..":")
        field.sX,field.y = screen:getCursorPos() -- input area start x point
        field.eX = tTerm.screen.x-2 --end x point
        field.lX = field.eX-field.sX --total field length
        screen:setTextColor(field.textColor)
        screen:setBackgroundColor(field.backgroundColor)
        screen:write(string.sub(field.value,1,field.lX))
        field.cX = (screen:getCursorPos())-field.sX --cursor pos
        field.scroll = math.max(0,#field.value-field.lX) --scroll value
        screen:drawLine(field.cX+field.sX,field.y,field.eX,field.y,field.backgroundColor)
        for iX = field.sX,field.eX do
          inputTouchMap[iX][field.y] = i
        end
      end
      screen:setCursorBlink(true)
      tInputs.enabled = 1
      screen:setCursorPos(tInputs[1].cX+tInputs[1].sX,tInputs[1].y)
    end
    local function refreshField(field)
     --updates input fields
      screen:setLayer(screenLayer)
      field = tInputs[field]
      field.scroll = (
        field.cX > field.lX 
        and math.min(field.scroll+(field.cX-field.lX),#field.value-field.lX)
        or field.cX < 0
        and math.max(field.scroll-math.abs(field.cX),0)
        or field.scroll
      )
      field.cX = math.max(0,math.min(field.cX,field.lX))
      local fieldString = field.value:sub(field.scroll+1,field.lX+field.scroll+1)
      screen:setCursorPos(field.sX,field.y)
      screen:setBackgroundColor(field.backgroundColor)
      screen:write(fieldString..string.rep(" ",math.max(0,field.lX-#fieldString+1)))
      screen:setCursorPos(field.sX+field.cX,field.y)
    end
    local eventHandlers = {
      mouse_click = function(tEvent)
        local x,y = tEvent[3],tEvent[4]
        if inputTouchMap[x][y] then --input bar clicked
          tInputs.enabled = inputTouchMap[x][y]
          local enabled = tInputs.enabled
          screen:setCursorPos(math.min(#tInputs[enabled].value+tInputs[enabled].sX,x),y)
          tInputs[enabled].cX = (screen:getCursorPos())-tInputs[enabled].sX
        elseif buttonTouchMap[x][y] then
          return endExecution(buttonTouchMap[x][y])
        end
      end,
      char = function(tEvent)
        if tInputs.enabled then
          local field = tInputs[tInputs.enabled]
          if tEvent[2]:match(field.accepted) and #field.value < field.charLimit then -- check for accepted character and character limit
            local curs = field.cX+field.scroll
            field.value = field.value:sub(1,curs)..tEvent[2]..field.value:sub(curs+1)
            field.cX = field.cX+1
            refreshField(tInputs.enabled)
          end
        end
      end,
      key = function(tEvent)
        local key = tEvent[2]
        if tInputs.enabled then
          local field = tInputs[tInputs.enabled]
          --input box
          if key == 14
          and field.cX > 0 then
            --backspace
            local curs = field.cX+field.scroll
            field.value = field.value:sub(1,curs-1)..field.value:sub(curs+1)
            if field.scroll > 0 then
              field.scroll = field.scroll-1
            else
              field.cX = field.cX-1
            end
          elseif key == 205 then --right arrow
            field.cX = field.cX+1
          elseif key == 203 then --left arrow
            field.cX = field.cX-1
          elseif key == 200 then --up arrow
            tInputs.enabled = math.max(1,tInputs.enabled-1)
          elseif key == 208 then --down arrow
            tInputs.enabled = math.min(#tInputs,tInputs.enabled+1)
          elseif key == 211 then --delete
            local curs = field.cX+field.scroll
            if #field.value <= 1 and curs == 0 then
              field.value = ""
            else
              field.value = field.value:sub(1,curs)..field.value:sub(curs+2)
            end
          elseif key == 207 then --end
            field.cX = field.lX
            field.scroll = #field.value-field.lX
          elseif key == 199 then --home
            field.cX = 1
            field.scroll = 0
          elseif key == 28 then --enter
            if tInputs.enabled == #tInputs then
              return endExecution("Ok")
            else
              tInputs.enabled = tInputs.enabled+1
            end
          end
          refreshField(tInputs.enabled)
        else --no input boxes
          if key == 28 then --enter
            return endExecution("Ok")
          end
        end
      end,
      chat_command = function(tEvent)
        local command = tEvent[2]:lower()
        for i=1,#tButtons do
          if tButtons[i].name:lower() == command then
            return endExecution(tButtons[i].name)
          end
        end
        local tCommand = {}
        for word in command:gmatch"%S+" do
          local num = tonumber(word)
          if num then
            tCommand[#tCommand+1] = num
          else
            tCommand[#tCommand+1] = word:lower()
          end
        end
        if tInputs.enabled then
          local field
          if type(tCommand[1]) == "number" then
            field = math.max(1,math.min(#tInputs,tCommand[1]))
            tInputs[field].value = table.concat(tCommand," ",2)
            refreshField(field)
          else
            for i=1,#tInputs do
              if command:match(tInputs[i].name:lower()) then
                tInputs[i].value = command:match(tInputs[i].name:lower().." (.+)")
                refreshField(i)
                break
              end
            end
          end
        end
      end
    }
    if animated then
      text.timerId = os.startTimer(text[1].renderTime)
      eventHandlers.timer = function(tEvent)
        if tEvent[2] == text.timerId then
          text.activeFrame = text.activeFrame+1
          if text.activeFrame > #text then
            text.activeFrame = 1
          end
          screen:setLayer(screenLayer)
          screen:setBackgroundColor(tColors.inputBox)
          screen:setTextColor(tColors.inputBoxText)
          for i,line in ipairs(text[text.activeFrame].lines) do
            screen:setCursorPos(2,box.top+i)
            screen:write(line)
          end
          text.timerId = os.startTimer(text[text.activeFrame].renderTime)
          return true
        else
          eventQueue[#eventQueue+1] = tEvent
        end
      end
    else
      eventHandler.timer = function(tEvent)
        eventQueue[#eventQueue+1] = tEvent
        return true
      end
    end
    if customEvent then
      for k,v in pairs(customEvent) do
        local mainFunc = eventHandlers[k]
        eventHandlers[k] = function(tEvent)
          local button = v(tEvent)
          if button then
            return endExecution(button)
          end
          if mainFunc then
            return mainFunc(tEvent)
          end
        end
      end
    end
    eventHandler.switch(eventHandlers)
    while true do
    --user interaction begins
      local event,tRes,reInput = eventHandler.pull()
      if type(event) == "string" then
        return event,tRes,reInput
      end
    end
  end,
  scroll = function(text,tItems,multiSelection,reinput,customEvent)
    local screenLayer = screen.layers.dialogue+activeInputs
    inputOpen = true
    screen:setLayer(screenLayer)
    activeInputs = activeInputs+1
    local scroll = 0
    local selected
    if multiSelection then
      selected = {}
      for i,v in ipairs(tItems) do
        selected[i] = type(v) == "table" and v.selected and true or nil
      end
    else
      selected = 1
    end
    local oldHandlers = eventHandler.active--stores currently in use event handlers, prior to switch
    local function endExecution(event,selection)
      --closes input box and returns event and the values in the input fields
      eventHandler.switch(oldHandlers,true)
      screen:delLayer(screenLayer)
      inputOpen = (screenLayer ~= screen.layers.dialogue)
      activeInputs = activeInputs-1
      return event, selection
    end
    --set up text
    local lineLength = tTerm.screen.x-2 --max line length
    if type(text) == "table" then --converts text to string if it's a table
      text = table.concat(text,"\n")
    end
    glasses.log.write(text)
    local tLine = string.lineFormat(text,lineLength)
    local maxLines = 3
    if #tLine > maxLines then
      window.text(table.concat(tLine,"\n",maxLines+1))
      tLine[maxLines+1] = nil
    end
    local selectionLength = tTerm.screen.x-5
    for i,selection in ipairs(tItems) do
      tItems[i] = (
        type(selection) == "table"
        and selection
        or {text = selection}
      )
      selection = tItems[i]
      setmetatable(selection,{__index = scrollDefaults})
      local text = string.rep(" ",math.max(0,math.floor((selectionLength-#selection.text)/2)))..selection.text
      selection.string = text..string.rep(" ",math.max(selectionLength-#text,0))
    end
    local touchMap = class.matrix.new(2)
    local box = {
      height = 2+math.min(#tItems+#tLine,tTerm.screen.y-5),
      width = tTerm.screen.x
    }
    box.top = tTerm.screen.yMid-math.ceil(box.height/2)
    box.bottom = box.top+box.height
    screen:drawBox(2,box.top+1,box.width-1,box.bottom-1,tColors.inputBox)
    screen:drawFrame(1,box.top,box.width,box.bottom,tColors.inputBoxBorder)
    screen:setBackgroundColor(tColors.inputBox)
    screen:setTextColor(tColors.inputBoxText)
    for i,line in ipairs(tLine) do
      screen:setCursorPos(tTerm.screen.xMid-math.ceil(#line/2),box.top+i)
      screen:write(line)
    end
    local visibleSelections = tTerm.screen.y-6-#tLine
    local selFunc = (
      multiSelection
      and function(clickX,clickY)
        local newSelection = clickY-box.top-#tLine+scroll
        screen:setLayer(screenLayer)
        if selected[newSelection] then --de selection
          selected[newSelection] = nil
          local selection = tItems[newSelection]
          screen:setTextColor(selection.uText)
          screen:setBackgroundColor(selection.uBackground)
          screen:setCursorPos(4,clickY)
          screen:write(selection.string)
        else --new selection
          selected[newSelection] = true
          local selection = tItems[newSelection]
          screen:setTextColor(selection.sText)
          screen:setBackgroundColor(selection.sBackground)
          screen:setCursorPos(4,clickY)
          screen:write(selection.string)
        end
      end
      or function(clickX,clickY)
        local newSelection = clickY-box.top-#tLine+scroll
        if newSelection == selected then
          return
        end
        screen:setLayer(screenLayer)
        if visibleSelections+scroll >= selected
        and scroll < selected then
          local selection = tItems[selected]
          screen:setTextColor(selection.uText)
          screen:setBackgroundColor(selection.uBackground)
          screen:setCursorPos(4,selected+box.top+#tLine-scroll)
          screen:write(selection.string)
        end
        local selection = tItems[newSelection]
        screen:setTextColor(selection.sText)
        screen:setBackgroundColor(selection.sBackground)
        screen:setCursorPos(4,clickY)
        screen:write(selection.string)
        selected = newSelection
      end
    )
    for i = 1,visibleSelections do
      if not tItems[i] then
        break
      end
      local iY = i+box.top+#tLine
      for iX = 4,#tItems[i].string+4 do
        touchMap[iX][iY] = selFunc
      end
    end
    local function refresh()
      screen:setLayer(screenLayer)
      for iY=1+scroll,scroll+visibleSelections do
        if not tItems[iY] then
          return
        end
        local y = box.top+#tLine+iY-scroll
        screen:setCursorPos(4,y)
        if multiSelection then
          screen:setBackgroundColor(selected[iY] and tItems[iY].sBackground or tItems[iY].uBackground)
          screen:setTextColor(selected[iY] and tItems[iY].sText or tItems[iY].uText)
        else
          screen:setBackgroundColor(selected == iY and tItems[iY].sBackground or tItems[iY].uBackground)
          screen:setTextColor(selected == iY and tItems[iY].sText or tItems[iY].uText)
        end
        screen:write(tItems[iY].string)
      end
    end
    refresh()
    local y = box.bottom-1
    local x = tTerm.screen.xMid-6
    screen:setCursorPos(x,y)
    screen:setBackgroundColor(tColors.inputButton)
    screen:setTextColor(tColors.inputButtonText)
    screen:write(" Cancel ")
    screen:setCursorPos(x+9)
    screen:write(" Ok ")
    local cancelFunc = function()
      return endExecution("Cancel")
    end
    local okFunc = (
      multiSelection
      and function()
        local tSelected = {}
        for k in pairs(selected) do
          tSelected[#tSelected+1] = tItems[k].text
        end
        return endExecution("Ok",tSelected)
      end
      or function()
        return endExecution("Ok",tItems[selected].text)
      end
    )
    for i = x,x+7 do
      touchMap[i][y] = cancelFunc
    end
    for i = x+9,x+12 do
      touchMap[i][y] = okFunc
    end
    local eventHandlers = {
      mouse_click = function(tEvent)
        local x,y = tEvent[3],tEvent[4]
        local func = touchMap[x][y]
        if func then
          return func(x,y)
        end
      end,
      mouse_scroll = function(tEvent)
        local oldScroll = scroll
        scroll = math.max(0,math.min(scroll+tEvent[2],#tItems-visibleSelections))
        if scroll ~= oldScroll then
          refresh()
        end
      end,
      key = function(tEvent)
        local key = tEvent[2]
        if key == 28 then
          return endExecution("Ok",selected)
        end
      end
    }
    if customEvent then
      for k,v in pairs(customEvent) do
        local mainFunc = eventHandlers[k]
        eventHandlers[k] = function(tEvent)
          local customEvent = v(tEvent)
          if button then
            return endExecution(customEvent,selected)
          end
          if mainFunc then
            return mainFunc(tEvent,selected)
          end
        end
      end
    end
    eventHandler.switch(eventHandlers)
    while true do
    --user interaction begins
      local event,selection = eventHandler.pull()
      if type(event) == "string" then
        if reinput then
          for i,item in ipairs(tItems) do
            item.selected = selected[i]
          end
          reinput = function(reText)
            return window.scroll(reText,tItems,multiSelection,true,customEvent)
          end
        end
        return event,selection,reinput
      end
    end
  end
}
--[[----------------------------------------------------------------------------------------------------------
Common inputs
----------------------------------------------------------------------------------------------------------]]--
local colorSelect = {}
for k,v in pairs(colors) do
  if type(v) == "number" then
    k = k:gsub("(%u)",function(l) return " "..l:lower() end)
    k = k:sub(1,1):upper()..k:sub(2)
    colorSelect[#colorSelect+1] = {
      text = k,
      uText = v ~= tColors.scrollBoxSelectText and tColors.scrollBoxSelectText or colors.black,
      uBackground = v
    }
  end
end
dialogue = {
  selectTurtle = function(text,multi)
    local connected = {}
    for k,v in pairs(tMode.sync.ids) do
      if v == "turtle" then
        connected[#connected+1] = k.." - Turtle"
      end
    end
    local ids,button
    if #connected > 1 then
      button,ids = window.scroll(text,connected,multi)
      if button == "Cancel" then
        return false
      end
    else
      ids = connected
    end
    local retIDs = {}
    local nID
    for i,id in ipairs(ids) do
      nID = tonumber(id:match"%d+")
      retIDs[nID] = true
    end
    return retIDs, multi and #ids or nID
  end,
  selectColor = function(text)
    local event,selected = window.scroll(text,colorSelect)
    if event ~= "Cancel" then
      selected = selected:lower()
      local space = selected:find" "
      if space then
        selected = selected:sub(1,space-1)..string.upper(selected:sub(space+1,space+1))..selected:sub(space+2)
      end
      return selected
    end
    return event
  end,
  save = function(text)
    local fileName = tFile.blueprint
    local button,tRes,reInput
    if not fileName then
      button, tRes, reInput = window.text(
        text or "No file name for current blueprint,",
        {
          "Cancel",
          "Ok"
        },
        {
          {
            name = "File name",
            value = "/",
            accepted = "."
          },
        },
        false,
        true
      )
    end
    while button and button ~= "Cancel" do
      fileName = not tFile.blueprint and tRes["File name"] or fileName
      if not fileName then
        button,tRes,reInput = reinput("Invalid file name!")
      elseif fs.exists(fileName..".TAb") then
        button = window.text(
          fileName.." already exists!\n Overwrite?",
          {
            "Cancel",
            "Overwrite"
          }
        )
        if button == "Overwrite" or button == "Ok" then
          break
        end
        button,tRes,reInput = reInput("Overwrite of "..fileName.." cancelled. Input new file name.")
      else
        break
      end
    end
    if button == "Cancel" then
      return false
    end
    tBlueprint:save(fileName)
    tFile.blueprint = fileName
    window.text("Successfully saved "..fileName..".TAb.")
    return true
  end
}