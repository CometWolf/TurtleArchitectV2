local folder = tFile.folder
local tGitSha
local file = fs.open(folder.."/".."gitSha","r")
if file then
  tGitSha = file and textutils.unserialize(file.readAll()) or {}
  file.close()
else
  tGitSha = {}
end
local tContents = {}
local getContents
local tActive = {}
local success,failure
getContents = function(path)
  tActive[#tActive+1] = true
  path = path or ""
  success = function(tEvent)
    table.remove(tActive,1)
    local web = tEvent[3]
    local sContents = web.readAll()
    web.close()
    local _s,remainder = sContents:find'"name":"'
    local name = sContents:match'"name":"(.-)"'
    while name do
      sContents = sContents:sub(remainder)..""
      local sha = sContents:match'"sha":"(.-)"'
      if tGitSha[path.."/"..name] ~= sha then
        tGitSha[path.."/"..name] = sha
        local url = sContents:match'html_url":"(.-)"'
        url = url:gsub("https://","https://raw.")
        url = url:gsub("blob/","")
        if sContents:match'"type":"(.-)"' == "file" then
          tContents[folder..path.."/"..name] = url
        else
          local newFolder = folder..path.."/"..name
          if not fs.exists(newFolder) then
            fs.makeDir(newFolder)
          end
          if not getContents(path.."/"..name) then
            return false
          end
        end
      end
      _s,remainder = sContents:find'"name":"'
      name = sContents:match'"name":"(.-)"'
    end
  end
  failure = function(tEvent)
    table.remove(tActive,1)
    if path ~= "" then
      local button = window.text(
        "Error: Failed to get contents of "..path..". Retry?",
        {
          "No",
          "Yes"
        }
      )
      if button == "No" then
        return false
      else
        getContents("https://api.github.com/repos/CometWolf/TurtleArchitectV2/contents"..path)
      end
    else
      window.text"Error: Github download limit exceeded"
      return false
    end
  end
  http.request("https://api.github.com/repos/CometWolf/TurtleArchitectV2/contents"..path)
  if not main then
    eventHandler.active.http_success = success
    eventHandler.active.http_failure = failure
  end
end

getContents(nil,true)
local button = window.text(
  {
    {
      text = "Looking for updates"
    },
    {
      text = "Looking for updates."
    },
    {
      text = "Looking for updates.."
    },
    {
      text = "Looking for updates..."
    }
  },
  {
    "Cancel"
  },
  false,
  {
    http_success = success,
    http_failure = failure,
    timer = function()
      if #tActive == 0 then
        return "Done"
      end
    end
  }
)
if button == "Done" then
  local updated = false
  for file,url in pairs(tContents) do
    updated = true
    local saveFile = fs.open(file,"w")
    local webFile
    while not webFile do
      webFile = http.get(url)
      if not webFile then
        local button = window.text(
          "Update of "..file.." failed. Retry?",
          {
            "No",
            "Yes"
          }
        )
        if button == "No" then
          saveFile.close()
          return false
        end
      end
    end   
    saveFile.write(webFile.readAll())
    saveFile.close()
    webFile.close()
  end
  if updated then
    local tUpdated = {}
    for k,v in pairs(tContents) do
      tUpdated[#tUpdated+1] = k
    end
    local file = fs.open(folder.."/".."gitSha","w")
    file.write(textutils.serialize(tGitSha))
    file.close()
    window.text("Updated:\n"..table.concat(tUpdated,"\n"))
    return true
  else
    window.text("No update available")
    return false
  end
end