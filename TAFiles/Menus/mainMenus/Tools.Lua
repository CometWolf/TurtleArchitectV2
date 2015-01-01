tTool.change = function(tool,b1,b2) --tool change function
  if b1 then
    local deselected = tTool.deselected[tTool[b1].tool]
    if deselected then
      deselected()
    end
    tTool[b1].prevTool = tTool[b1].tool
    tTool[b1].tool = tool
    tTool[b1].prevDouble = tTool[b1].double
    if b2 then
      local deselected = tTool[b1].tool ~= tTool[b2].tool and tTool.deselected[tTool[b2].tool]
      if deselected then
        deselected()
      end
      tTool[b2].prevTool = tTool[b2].tool
      tTool[b2].tool = tool
      tTool[b2].prevDouble = tTool[b2].double
      tTool[b2].double = true
      tTool[b1].double = true
    elseif tTool[b1].double then
      tTool[b1].double = false
      b2 = b1 == 1 and 2 or 1
      tTool[b2].tool = tTool[b2].prevTool
      tTool[b2].prevTool = tTool[b2].tool
      tTool[b2].double = tTool[b2].prevDouble
      tTool[b2].prevDouble = true
    end
  end
  if tTool.shape.eX or tTool.clipboard or tTool.select.sX then
    tTool.select = {}
    tTool.clipboard = false
    tTool.shape = {}
    screen:clearLayer(screen.layers.toolsOverlay)
  end
  renderBottomBar()
end

local menu = {
  enabled = true
}
codeEnv = { --Environment for the code tool
  tool = {}, --holds tool codefuncs
  class = { --class table for creating layers and blueprints
    layer = class.layer.new,
    blueprint = class.blueprint.new
  },
  window = setmetatable(
    {},
    {__index = window}
  ),
  debug = debug --direct inheritance,cause idgaf
}
--load tools
for _k,file in pairs(fs.list(tFile.toolFolder)) do
  if file ~= "Code.Lua" then
    local tool = loadFile(tFile.toolFolder.."/"..file,progEnv)
    local toolName = file:match"(.+)%.Lua"
    tTool[toolName] = tool.renderFunc
    tTool.selected[toolName] = tool.selectFunc
    tTool.deselected[toolName] = tool.deselectFunc
    codeEnv.tool[toolName] = tool.codeFunc
    menu[tool.menuOrder] = {
      name = toolName,
      enabled = tool.enabled,
      help = tool.help,
      func = tool.selectFunc
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
  enabled = tool.enabled,
  help = tool.help,
  func = tool.selectFunc
}
return menu