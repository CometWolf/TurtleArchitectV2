local tEnv = {...}
tEnv = tEnv[1]
local sandboxG = {}
for k,v in pairs(_G) do
  sandboxG[k] = v
end
sandboxG._G = sandboxG
setmetatable(
  tEnv,
  {
    __index = sandboxG
  }
)
local tool  
tool = {
  menuOrder = 8, --menu order, 1 being top
  selectFunc = function(button)
    local button,tRes,reInput = input(
      "Input path to code tool file",
      {
        "Cancel",
        "Ok",
        "Direct"
      },
      {
        {
          name = "Path",
          value = "/",
          accepted = "."
        }
      },
      false,
      true
    )
    while button ~= "Cancel" do
      
    end
    tTool.change("Code",button)
  end,
  renderFunc = function(event,button,x,z,color)
    
  end
}
return tool