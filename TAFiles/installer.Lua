local minification = true
local folder = tFile.folder:match"(.)/TAFiles" or ""
local tGitSha
local file = fs.open(tFile.folder.."/".."gitSha","r")
if file then
  tGitSha = file and textutils.unserialize(file.readAll()) or {}
  file.close()
else
  tGitSha = {}
end
local updateFiles = {}
local getContents
local tActive = {}
getContents = function(path,main)
  tActive[#tActive+1] = true
  local success = function(tEvent)
    local web = tEvent[3]
    local path = tEvent[2]:match"https://api.github.com/repos/CometWolf/TurtleArchitectV2/contents(.+)" or ""
    local sContents = web.readAll()
    web.close()
    local _s,remainder = sContents:find'"name":"'
    local name = sContents:match'"name":"(.-)"'
    while name do
      sContents = sContents:sub(remainder)..""
      local sha = sContents:match'"sha":"(.-)"'
      if name ~= "README.md" and tGitSha[path.."/"..name] ~= sha then
        tGitSha[path.."/"..name] = sha
        local url = sContents:match'html_url":"(.-)"'
        url = url:gsub("https://","https://raw.")
        url = url:gsub("blob/","")
        local type = sContents:match'"type":"(.-)"'
        if type == "file" then
          updateFiles[#updateFiles+1] = {
            file = folder..path.."/"..name,
            url = url
          }
        elseif type == "dir" then
          local newFolder = folder..path.."/"..name
          if not fs.exists(newFolder) then
            fs.makeDir(newFolder)
          end
          getContents(path.."/"..name)
        end
      end
      _s,remainder = sContents:find'"name":"'
      name = sContents:match'"name":"(.-)"'
    end
    table.remove(tActive,1)
  end
  local failure = function(tEvent)
    if path ~= "" then
      local button = window.text(
        "Error: Failed to get contents of "..path..". Retry?",
        {
          "No",
          "Yes"
        }
      )
      if button == "No" then
        return "Cancel"
      else
        http.request("https://api.github.com/repos/CometWolf/TurtleArchitectV2/contents"..path)
      end
    else
      window.text"Error: Github download limit exceeded"
      return "Cancel"
    end
  end
  http.request("https://api.github.com/repos/CometWolf/TurtleArchitectV2/contents"..path)
  if main then
    return success,failure
  else
    eventHandler.active.http_success = success
    eventHandler.active.http_failure = failure
  end
end

local fSuccess,fFailure = getContents("",true)
local button = window.text(
  {
    {
      text = "Looking for updates",
      renderTime = 0.2
    },
    {
      text = "Looking for updates.",
      renderTime = 0.2
    },
    {
      text = "Looking for updates..",
      renderTime = 0.2
    },
    {
      text = "Looking for updates...",
      renderTime = 0.2
    }
  },
  {
    "Cancel"
  },
  nil,
  {
    http_success = fSuccess,
    http_failure = fFailure,
    timer = function()
      if #tActive == 0 then
        return "Done"
      end
    end
  }
)
if button == "Done" then
  if #updateFiles > 0 then
    local button = window.text(
      "Update found!\nInstall?\nAll unsaved progress will be lost.",
      {
        "Cancel",
        "Ok"
      }
    )    
    if button == "Ok" then
      local updatingFile = 1
      local tUpdated = {}
      http.request(updateFiles[updatingFile].url)
      local button = window.text(
        {
          {
            text = "Updating",
            renderTime = 0.2
          },
          {
            text = "Updating.",
            renderTime = 0.2
          },
          {
            text = "Updating..",
            renderTime = 0.2
          },
          {
            text = "Updating...",
            renderTime = 0.2
          }
        },
        {
          "Cancel"
        },
        false,
        {
          http_success = function(tEvent)
            local fileName = updateFiles[updatingFile].file
            local saveFile = fs.open(fileName,"w")
            local webFile = tEvent[3]
            if fileName:match"TAFiles/Settings.Lua" then --settings file can't be minified
              saveFile.write(webFile.readAll())
            else
              local line = webFile.readLine()
              while line do
                saveFile.write((minification and (line:match"(%S.*)$" or "") or line).."\n")
                line = webFile.readLine()
              end
            end
            saveFile.close()
            webFile.close()
            tUpdated[#tUpdated+1] = updateFiles[updatingFile].file
            updatingFile = updatingFile+1
            if updatingFile > #updateFiles then
              return "Done"
            end
            http.request(updateFiles[updatingFile].url)
          end,
          http_failure = function()
            local button = window.text(
              "Update of "..updateFiles[updatingFile].file.." failed. Retry?",
              {
                "No",
                "Yes"
              }
            )
            if button == "No" then
              saveFile.close()
              return "Cancel"
            end
          end
        }
      )
      if button == "Cancel" then
        return false
      end
      local file = fs.open(tFile.folder.."/".."gitSha","w")
      file.write(textutils.serialize(tGitSha))
      file.close()
      window.text("Updated:\n"..table.concat(tUpdated,"\n"))
      return true
    end
    return false
  else
    window.text("No update available")
    return false
  end
end
