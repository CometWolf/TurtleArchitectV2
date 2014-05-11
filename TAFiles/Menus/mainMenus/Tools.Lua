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
    screen:clearLayer(screen.layers.toolsOverlay)
  end
end

local menu = {
  enabled = true
}
codeEnv = { --Environment for the code tool
  tool = {}, --holds tool codefuncs
  settings = {
    direct = false --whether to affect the blueprint directly, or through a pasted blueprint. this should only be enabled if your code is very light drawing wise.
  }
}
--load tools
for _k,file in pairs(fs.list(tFile.toolFolder)) do
  if file ~= "Code.Lua" then
    local tool = loadFile(tFile.toolFolder.."/"..file,progEnv)
    local toolName = file:match"(.+)%.Lua"
    tTool[toolName] = tool.renderFunc
    codeEnv.tool[toolName] = tool.codeFunc
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
local tool = loadFile(tFile.toolFolder.."/Code.Lua",getfenv())
tTool["Code"] = function(...) --since it changes, it has to be looked up on each call.
  tool.renderFunc(...)
end
menu[tool.menuOrder] = {
  name = "Code",
  enabled = true,
  func = function(button)
    tool.selectFunc(button)
    renderBottomBar()
  end
}
return menu