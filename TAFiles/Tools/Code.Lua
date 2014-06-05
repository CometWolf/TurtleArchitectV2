codeEnv.tool.select = tTool.change

codeEnv.getCanvas = function()
  return tBlueprint
end

codeEnv.getLayer = function(num)
  return tBlueprint[num or codeEnv.click.layer]
end

codeEnv.overlay = function(overlay,x,z)
  if not (overlay and x and z)
  or type(x) ~= "number"
  or type(z) ~= "number" 
  or type(overlay) ~= "table" 
  or not overlay.size then
    error("layer,number,number expected",2)
  end
  tTool.shape.sX = x
  tTool.shape.sZ = z
  local eX,eZ = overlay:size()
  tTool.shape.eX = eX+x
  tTool.shape.eZ = eZ+z
  tTool.shape.l = overlay
end

codeEnv.getOverlay = function()
  return tTool.shape.l
end

codeEnv.tool.brush = codeEnv.tool.Brush
codeEnv.tool.Brush = nil
codeEnv.tool.line = codeEnv.tool.Line
codeEnv.tool.Line = nil
for k,v in pairs(codeEnv.tool) do --setup proper environment access for the tool functions
  if type(v) == "function" then
    setfenv(v,progEnv)
  end
end

local tDisabled = { --disabled APIs and functions, edit them if you wish...
  fs = true,
  term = true,
  turtle = true,
  loadfile = true,
  dofile = true,
  io = true,
  paintutils = true,
  window = true,
  shell = true,
  multishell = true,
  print = true,
  write = true
}

for k,v in pairs(_G) do
  if tDisabled[k] then
    codeEnv[k] = (
      type(codeEnv[k]) == "table"
      and setmetatable({},{__index = function() error(k.." functions are disabled within the code tool!",2) end})
    ) or (
      function() error(k.." is disabled within the code tool!",2) end
    )
  elseif type(v) == "table" then
    codeEnv[k] = setmetatable({},{__index = v})
  end
end
codeEnv._G = codeEnv

for k,v in pairs(_G.colors) do
  if type(v) == "number" then
    codeEnv.colors[k] = colorKey[v]
    codeEnv.colours[k] = colorKey[v]
  end
end

setmetatable(
  codeEnv,
  {
    __index = _G,
    __metatable = false
  }
)

local tool  
tool = {
  menuOrder = 10, --menu order, 1 being top
  enabled = true,
  help = function(clickButton)
    local button = window.text(
      "The code tool is a very unique tool. Using regular Lua code, you can code your own tool directly. This code can either be input directly into the dialogue window, or loaded from a file",
      {
        "Ok",
        "Equip"
      }
    )
    if button == "Equip" then
      tool.selectFunc(clickButton)
      return
    end
    button = window.text(
      "Click information is stored in the click table under the keys:\nx,z,color,layer,button and event.\n",
      {
        "Ok",
        "Equip"
      }
    )
    if button == "Equip" then
      tool.selectFunc(clickButton)
      return
    end
    window.text(
      "Most of the default tools may be called from this code as well, indexed in the tool table.\ntool.hSquare(x1,z1,x2,z2,color,layer)\nIf not specified, click.color and click.layer is used for the color and layer respectively",
      {
        "Ok",
        "Equip"
      }
    )
    if button == "Equip" then
      tool.selectFunc(clickButton)
    end
  end,
  selectFunc = function(clickButton)
    local button,tRes,reInput = window.text(
      "Input path to code tool file\nor input code directly.",
      {
        "Cancel",
        "Load",
        "Edit",
        "Compile"
      },
      {
        {
          name = "Path",
          value = codeEnv.code or "/",
          accepted = "."
        }
      },
      false,
      true
    )
    while button ~= "Cancel" do
      local path = tRes.Path
      if button == "Compile" then
        local loadRes = {loadstring(path)}
        if not loadRes[1] then
          button,tRes,reInput = reInput("Error: "..loadRes[2])
        else
          setfenv(loadRes[1],codeEnv)
          codeEnv.code = path
          tool.renderFunc = function(event,button,x,z,color,layer)
            codeEnv.settings.direct = false
            codeEnv.click = {
              event = event,
              button = button,
              x = x+tTerm.scroll.x,
              z = z+tTerm.scroll.z,
              color = color,
              layer = layer
            }
            codeEnv.blueprint = class.blueprint.new(nil,true)
            local tCallRes = {pcall(loadRes[1])}
            if not tCallRes[1] then
              local button = window.text(
                "Code tool error:\n"..(tCallRes[2]:match"string:1: (.+)" or tCallRes[2]),
                {
                  "Ok",
                  "Edit"
                }
              )
              if button == "Edit" then
                tool.selectFunc()
              end
            elseif not codeEnv.settings.direct then
              tBlueprint:paste(codeEnv.blueprint,nil,nil,not tMode.overwrite)
              local syncObj = {
                sX = 0,
                sZ = 0,
                l = codeEnv.blueprint
              }
              sync(syncObj,"Paste")
              scroll()
            end
          end
          break
        end
      elseif button == "Edit" then
        local events = {}
        parallel.waitForAny(
          function()
            shell.run("edit "..path) --lmao, im actually using shell.run!
          end,
          function()
            while true do
              local tEvent = {os.pullEvent()}
              if tEvent[1] == "modem_message"
              or tEvent[1] == "timer" then
                events[#events+1] = tEvent
              end
            end
          end
        )
        screen:redraw()
        for i=1,#events do
          os.queueEvent(unpack(events[i]))
        end
        button,tRes,reInput = reInput"Input path to code tool file"
      else --button == Load, load code
        if not fs.exists(path) then
          button,tRes,reInput = reInput(path.." does not exist!")
        else
          local loadRes = {loadfile(path)}
          if not loadRes[1] then
            button,tRes,reInput = reInput("Error: "..loadRes[2])
          else
            setfenv(loadRes[1],codeEnv)
            codeEnv.code = path
            tool.renderFunc = function(event,button,x,z,color,layer)
              codeEnv.settings.direct = false
              codeEnv.click = {
                event = event,
                button = button,
                x = x+tTerm.scroll.x,
                z = z+tTerm.scroll.z,
                color = color,
                layer = layer
              }
              codeEnv.blueprint = class.blueprint.new(nil,true)
              local tCallRes = {pcall(loadRes[1])}
              if not tCallRes[1] then
                local button = window.text(
                  "Code tool error:\n"..tCallRes[2],
                  {
                    "Ok",
                    "Edit"
                  }
                )
                if button == "Edit" then
                  tool.selectFunc()
                end
              elseif not codeEnv.settings.direct then
                tBlueprint:paste(codeEnv.blueprint,nil,nil,not tMode.overwrite)
                local syncObj = {
                  sX = 0,
                  sZ = 0,
                  l = codeEnv.blueprint
                }
                sync(syncObj,"Paste")
                scroll()
              end
            end
            break
          end
        end
      end
    end
    if button ~= "Cancel" then
      tTool.change("Code",clickButton)
    end
  end,
  renderFunc = function(event,button,x,z,color,layer)
    
  end
}
return tool