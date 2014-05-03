for k,v in pairs(codeEnv.tool) do
  if type(v) == "function" then
    setfenv(v,progEnv)
  end
end

local sandboxG = {}
for k,v in pairs(_G) do
  sandboxG[k] = v
end
sandboxG._G = sandboxG
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
for k,v in pairs(tDisabled) do
  sandboxG[k] = (
    type(sandboxG[k]) == "table"
    and setmetatable({},{__index = function() error(k.." functions are disabled within the code tool!",2) end})
  ) or (
    function() error(k.." is disabled within the code tool!",2) end
  )
end
setmetatable(codeEnv,{__index = sandboxG})

codeEnv.debug = debug

local tool  
tool = {
  menuOrder = 8, --menu order, 1 being top
  selectFunc = function(clickButton)
    local button,tRes,reInput = input(
      "Input path to code tool file",
      {
        "Cancel",
        "Ok",
        "Edit",
        "Direct"
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
      if button == "Direct" then
        local loadRes = {loadstring(path)}
        if not loadRes[1] then
          button,tRes,reInput = reInput("Error: "..loadRes[2])
        else
          setfenv(loadRes[1],codeEnv)
          codeEnv.code = path
          tool.renderFunc = function(event,button,x,z,color,layer)
            codeEnv.event = event
            codeEnv.button = button
            codeEnv.x = x+tTerm.scroll.x
            codeEnv.z = z+tTerm.scroll.z
            codeEnv.color = color
            codeEnv.layer = layer
            loadRes[1]()
          end
          break
        end
      elseif button == "Edit" then
        shell.run("Edit "..path) --lmao, im actually using shell.run!
        button,tRes,reInput = reInput"Input path to code tool file"
      else --button == ok, load code
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
              codeEnv.event = event
              codeEnv.button = button
              codeEnv.x = x+tTerm.scroll.x
              codeEnv.z = z+tTerm.scroll.z
              codeEnv.color = color
              codeEnv.layer = layer
              loadRes[1]()
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