tTool.change = function(tool,b1,b2) --tool change function
  if b1 then
    tTool[b1].tool = tool
    if b2 then
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
--load tools
for _k,file in pairs(fs.list(tFile.toolFolder)) do
  local tool = loadFile(tFile.toolFolder.."/"..file,progEnv)
  tTool[file:match"(.+)%.Lua"] = tool.renderFunc
  menu[tool.menuOrder] = {
    name = file:match"(.+)%.Lua",
    enabled = true,
    func = function(button)
      tool.selectFunc(button)
      renderBottomBar()
    end
  }
end
return menu