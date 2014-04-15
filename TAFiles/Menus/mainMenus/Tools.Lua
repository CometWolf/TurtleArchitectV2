local menu
menu = {}
--load tools
for _k,file in pairs(fs.list(tFile.toolFolder)) do
  local tool = loadFile(tFile.toolFolder.."/"..file,progEnv)
  tTool[file:match"(.+)%.Lua"] = tool.renderFunc
  menu[tool.menuOrder] = {
    name = file:match"(.+)%.Lua",
    func = function(button)
      tool.selectFunc(button)
      renderBottomBar()
    end
  }
end
return menu