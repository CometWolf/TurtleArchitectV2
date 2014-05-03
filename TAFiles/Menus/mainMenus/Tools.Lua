tTool.change = function(tool,b1,b2) --tool change function
  if b1 then
    tTool[b1].prevTool = tTool[b1].tool
    tTool[b1].tool = tool
    if b2 then
      tTool[b2].prevTool = tTool[b2].tool
      tTool[b2].tool = tool
    end
  end
  if tTool.shape.eX or tTool.clipboard or tTool.select.sX then
    tTool.select = {}
    tTool.clipboard = false
    tTool.shape = {}
    screen:delLayer(screen.layers.toolsOverlay)
  end
end

local menu = {
  enabled = true
}
local codeFuncs = {} --holds all the code functions for the code tool
--load tools
for _k,file in pairs(fs.list(tFile.toolFolder)) do
  if file ~= "Code.Lua" then
    local tool = loadFile(tFile.toolFolder.."/"..file,progEnv)
    local toolName = file:match"(.+)%.Lua"
    tTool[toolName] = tool.renderFunc
    codeFuncs[toolName] = tool.codeFunc
    menu[tool.menuOrder] = {
      name = toolName,
      enabled = tool.enabled or true,
      func = function(button)
        tool.selectFunc(button)
        renderBottomBar()
      end
    }
  end
end

--code tool must be loaded last
local tool = loadFile(tFile.toolFolder.."/Code.Lua",progEnv,codeFuncs) 
tTool["Code"] = tool.renderFunc
menu[tool.menuOrder] = {
  name = "Code",
  enabled = false,
  func = function(button)
    tool.selectFunc(button)
    renderBottomBar()
  end
}
return menu