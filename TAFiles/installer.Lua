local tArgs = {...}
local folder = tArgs[1] or ""
local tContents = {}
local getContents
getContents = function(path,main)
  tContents = main and {} or tContents
  path = path or ""
  print("Scanning Github repo "..path.." for files...")
  local web = http.get("https://api.github.com/repos/CometWolf/TurtleArchitectV2/contents"..path)
  assert(web,(path ~= path and "Error: Failed to get contents of "..path) or "Error: Github download limit exceeded")
  local sContents = web.readAll()
  web.close()
  local _s,remainder = sContents:find'"name":"'
  local name = sContents:match'"name":"(.-)"'
  while name do
    sContents = sContents:sub(remainder)..""
    local url = sContents:match'html_url":"(.-)"'
    assert(url,"Error: Failed to get the url of "..path.."/"..name)
    url = url:gsub("https://","https://raw.")
    url = url:gsub("blob/","")
    if sContents:match'"type":"(.-)"' == "file" then
      tContents[folder..path.."/"..name] = url
      print("Found "..path.."/"..name)
    else
      local newFolder = folder..path.."/"..name
      if not fs.exists(newFolder) then
        print("Creating directory "..newFolder)
        fs.makeDir(newFolder)
      end
      getContents(path.."/"..name)
    end
    _s,remainder = sContents:find'"name":"'
    name = sContents:match'"name":"(.-)"'
  end
end
local createPath
getContents()
for file,url in pairs(tContents) do
  local saveFile = fs.open(file,"w")
  print("Downloading file "..file)
  print(url)
  local webFile
  while not webFile do
    webFile = http.get(url)
    if not webFile then
      print("Download failed. Retry? (Y/N)")
      while true do
        local _e,key = os.pullEvent"key"
        if key == 21 then --Y
          print"Retrying..."
          break
        elseif key == 49 then --N
          print"Installation canceled"
          saveFile.close()
          return
        end
      end
    end
  end   
  saveFile.write(webFile.readAll())
  saveFile.close()
  webFile.close()
end
print("Sucessfully installed Turtle Architect V2")