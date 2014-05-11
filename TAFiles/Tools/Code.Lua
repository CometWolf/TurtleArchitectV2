codeEnv.getCanvas = function()
  return tBlueprint
end

codeEnv.tool.brush = codeEnv.tool.Brush
codeEnv.tool.Brush = nil
for k,v in pairs(codeEnv.tool) do --setup proper environment access for the tool functions
  if type(v) == "function" then
    setfenv(v,progEnv)
  end
end

local tDisabled = { --disabled APIs and functions, edit them if you wish...
  fs = true,
  term = true,
  turtle = true,
  io = true,
  http = true,
  paintutils = true,
  window = true,
  shell = true,
  multishell = true,
  print = true,
  write = true
}

setmetatable(codeEnv,{__index = _G})
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
  end
end

codeEnv.debug = debug

local tool  
tool = {
  menuOrder = 8, --menu order, 1 being top
  selectFunc = function(clickButton)
    local button,tRes,reInput = input(
      "Input path to code tool file",
      {
        "Cancel",
        "Load",
        "Edit",
        "Execute"
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
      if button == "Execute" then
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
            loadRes[1]()
            if not codeEnv.settings.direct then
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
        shell.run("Edit "..path) --lmao, im actually using shell.run!
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
              loadRes[1]()
              if not codeEnv.settings.direct then
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