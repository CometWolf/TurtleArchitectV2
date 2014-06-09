local main = { --note that the menus are numbered from the bottom and up
  [6] = "Blueprint",
  [5] = "Layer",
  [4] = "Tools",
  [3] = "Turtle",
  [2] = "Sync",
  [1] = "Settings",
}

for i = 1,#main do
  main[i] = {
    name = main[i],
    items = loadFile(tFile.mainMenuFolder.."/"..main[i]..".Lua",progEnv)
  }
  main[i].enabled = main[i].items.enabled
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

main.enabled = function()
  local enabled = 0
  for i,menu in ipairs(main) do
    if type(menu.enabled) = function and menu.enabled() or menu.enabled == true then
      enabled = enabled+1
    end
  end
  return enabled
end

return main