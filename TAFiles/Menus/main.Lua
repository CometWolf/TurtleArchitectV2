local main = {
  [1] = "Blueprint",
  [2] = "Layer",
  [3] = "Tools",
  [4] = "Turtle",
  [5] = "Settings",
}
if not turtle then --disable turtle menu on computers
  for i=1,#main do
    if main[i] == "Turtle" then
      table.remove(main,i)
      break
    end
  end
end

for i = 1,#main do
  main[i] = {
    name = main[i],
    items = loadFile(tFile.mainMenuFolder.."/"..main[i]..".Lua",progEnv)
  }
  main[main[i].name] = main[i]
end

--create menu strings
for iMain = 1,#main do
  local items = main[iMain].items
  local longest = #main[iMain].name
  for iItems = 1,#items do
    longest = math.max(longest,#items[iItems].name)
  end
  longest = longest/2 --center text
  for iItems = 1,#items do
    local name = items[iItems].name
    items[iItems].string = string.rep(" ",math.floor(longest+1-(#name/2)))..name..string.rep(" ",math.ceil(longest+1-(#name/2)))
  end
  local name = main[iMain].name
  main[iMain].string = string.rep(" ",math.floor(longest+1-(#name/2)))..name..string.rep(" ",math.ceil(longest+1-(#name/2)))
end

return main