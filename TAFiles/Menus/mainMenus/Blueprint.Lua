local menu
menu = {
  enabled = true,
  [1] = {
    name = "Create new...",
    enabled = true,
    help = function()
      window.text"Creates a new blueprint and unloads the current one."
    end,
    func = function()
      local button, tRes, reInput = window.text(
        "Create new blueprint file...",
        {
          "Cancel",
          "Ok"
        },
        {
          {
            name = "File name",
            value = "/",
            accepted = "."
          }
        },
        false,
        true
      )
      while button ~= "Cancel" do
        local fileName = tRes["File name"]
        if not fileName then
          button,tRes,reInput = reInput"Invalid file name!"
        elseif fs.exists(fileName..".TAb") then
          button,tRes,reInput = reInput(fileName.." already exists!")
        else
          tBlueprint = class.blueprint.new()
          tFile.blueprint = fileName
          scroll()
          if tMode.layerBar then
            renderLayerBar(true)
          end
          window.text("Successfully created "..fileName..".TAb.")
          return
        end
      end
    end
  },
  [2] = {
    name = "Load...",
    enabled = true,
    help = function()
      window.text"Loads a previously saved blueprint."
    end,
    func = function()
      local button, tRes, reInput = window.text(
        "Load blueprint file",
        {
          "Cancel",
          "Ok",
          "Pastebin"
        },
        {
          {
            name = "File name",
            value = "/",
            accepted = "."
          },
        },
        false,
        true
      )
      while button ~= "Cancel" do
        local fileName = tRes["File name"]
        if button == "Pastebin" then
          if not fileName then
            button,tRes,reInput = reInput"Missing pastebin code parameter!"
          else
            fileName = fileName:match"[^/]+"
            local paste
            http.request("http://pastebin.com/raw.php?i="..fileName)
            local dlStatus = window.text(
              {
                {
                  text = "Downloading "..fileName..".",
                  renderTime = 0.2
                },
                {
                  text = "Downloading "..fileName.."..",
                  renderTime = 0.2
                },
                {
                  text = "Downloading "..fileName.."...",
                  renderTime = 0.2
                },
              },
              {
                "Cancel"
              },
              nil,
              {
                http_success = function(tEvent)
                  local web = tEvent[3]
                  paste = {}
                  local line = web.readLine()
                  while line do
                    paste[#paste+1] = line
                    line = web.readLine()
                  end
                  web.close()
                  return "Success"
                end,
                http_failure = function(tEvent)
                  button,tRes,reInput = reInput("Pastebin download of "..fileName.." failed!")
                  return "Failure"
                end
              }
            )
            if dlStatus == "Success" then
              local blueprint = tBlueprint.load(paste)
              if not blueprint then
                button,tRes,reInput = reInput(fileName.." was not a Turtle Architect file!")
              else
                tBlueprint = blueprint
                scroll()
                if tMode.layerBar then
                  renderLayerBar(true)
                end
                sync({blueprint = tBlueprint,blueprintName = false},"Blueprint load")
                window.text("Successfully downloaded "..fileName.."!")
                return
              end
            elseif dlStatus == "Cancel" then
              button,tRes,reInput = reInput"Load blueprint file"
            end
          end
        else
          local blueprint = tBlueprint.load(fileName)
          if not fileName then
            button,tRes,reInput = reInput("Missing blueprint file name parameter!")
          elseif not fs.exists(fileName..".TAb") then
            button,tRes,reInput = reInput(fileName.." does not exist!")
          elseif not blueprint then
            button,tRes,reInput = reInput(fileName.." is not a blueprint file!")
          elseif button == "Ok" then
            tFile.blueprint = fileName
            tBlueprint = blueprint
            scroll()
            if tMode.layerBar then
              renderLayerBar(true)
            end
            sync({blueprint = tBlueprint,blueprintName = fileName},"Blueprint load")
            window.text("Successfully loaded "..fileName..".TAb.")
            return
          end
        end
      end
    end
  },
  [3] = {
    name = "Save",
    enabled = true,
    help = function()
      window.text"Saves the current blueprint. If it has not been saved previously, a file name is requested"
    end,
    func = function()
      dialogue.save()
    end
  },
  [4] = {
    name = "Save as...",
    enabled = true,
    help = function()
      window.text"Save the current blueprint with a new name, or upload it to pastebin"
    end,
    func = function()
      local button, tRes, reInput = window.text(
        "Save current blueprint as",
        {
          "Cancel",
          "Ok",
          "Pastebin"
        },
        {
          {
            name = "File name",
            value = tFile.blueprint or "/",
            accepted = "."
          },
        },
        false,
        true
      )
      while button ~= "Cancel" do
        local fileName = tRes["File name"]
        if not fileName then
          button,tRes,reInput = reInput("Invalid file name!")
        elseif button == "Pastebin" then
          local upload = tBlueprint:save(true)
          http.request(
            "http://pastebin.com/api/api_post.php",
            "api_option=paste&"..
            "api_dev_key="..tPaste.key.."&"..
            "api_paste_format=text&"..
            "api_paste_name="..textutils.urlEncode(fileName or "Untitled").."&"..
            "api_paste_code="..textutils.urlEncode(upload)
          )
          local ulStatus = window.text(
            {
              {
                text = "Uploading "..fileName..".",
                renderTime = 0.2
              },
              {
                text = "Uploading "..fileName.."..",
                renderTime = 0.2
              },
              {
                text = "Uploading "..fileName.."...",
                renderTime = 0.2
              },
            },
            {
              "Cancel"
            },
            nil,
            {
              http_success = function(tEvent)
                local web = tEvent[3]
                local sResponse = web.readAll()
                web.close()      
                local sCode = string.match( sResponse, "[^/]+$" )
                window.text("Sucsessfully uploaded the blueprint to pastebin!\nCode: "..sCode.." \nURL: "..sResponse)
                return "Success"
              end,
              http_failure = function(tEvent)
                button,tRes,reInput = reInput("Pastebin upload failed!")
                return "Failure"
              end
            }
          )
          if ulStatus == "Success" then
            return
          elseif ulStatus == "Cancel" then
            button,tRes,reInput = reInput("Save current blueprint as")
          end
        elseif fs.exists(fileName..".TAb") then
          button,tRes,reInput = reInput(fileName.." already exists!")
        else
          tBlueprint:save(fileName)
          tFile.blueprint = fileName
          window.text("Successfully saved "..fileName..".TAb.")
          return
        end
      end
    end
  },
  [5] = {
    name = "Send...",
    enabled = function()
      return modem and true or false
    end,
    help = function()
      window.text"Transfer the currently loaded blueprint via rednet. This is only enabled if a modem is connected"
    end,
    func = function()
      local inRange = {}
      rednet.send("All","Ping")
      tTimers.scan.start()
      local scanRes = window.text(
        {
          {
            text = "Scanning",
            renderTime = 0.2
          },
          {
            text = "Scanning.",
            renderTime = 0.2
          },
          {
            text = "Scanning..",
            renderTime = 0.2
          },
          {
            text = "Scanning...",
            renderTime = 0.2
          },
        },
        {
          "Cancel"
        },
        nil,
        {
          timer = function(tEvent)
            if tTimers.scan.ids[tEvent[2]] then
              return "Done"
            end
          end,
          modem_message = function(tEvent)
            if tEvent[3] == modemChannel
            and type(tEvent[5]) == "table" --All Turtle Architect messages are sent as tables
            and tEvent[5].rID[os.id] then
              local data = tEvent[5]
              if data.event == "Success"
              and data.type == "Ping" then
                inRange[#inRange+1] = {
                  text = data.turtle and data.sID.." - Turtle" or data.sID.." - Computer"
                }
              end
            end
          end
        }
      )
      if scanRes == "Cancel" then
        return
      end
      if #inRange == 0 then
        window.text"No Turtle Architect computers in range!"
        return
      end
      local button,ids = window.scroll("Select IDs to transfer to:",inRange,true)
      if button == "Cancel" then
        return
      end
      local transferIds = {}
      for i,id in ipairs(ids) do
        transferIds[tonumber(id:match"%d+")] = true
      end
      rednet.send(transferIds,"Ping",
        {},
        function(id)
          rednet.send(id,"Blueprint transmission",
            {
              blueprint = tBlueprint,
              blueprintName = tFile.blueprint or "Untitled"
            }
          )
        end,
        function(id)
          window.text("Failed to connect to computer ID "..id)
        end
      )
    end
  },
  [6] = {
    name = "Flip...",
    enabled = true,
    help = function()
      window.text"Flip the entire blueprint vertically or horizontally"
    end,
    func = function()
      local button = window.text(
        "Flip the entire blueprint",
        {
          "Cancel",
          "Horizontal",
          "Vertical"
        }
      )
      if button == "Horizontal" then
        tBlueprint:flipX()
        scroll()
        sync({dir = "X",blueprint = true},"Flip")
      elseif button == "Vertical" then
        tBlueprint:flipZ()
        scroll()
        sync({dir = "Z",blueprint = true},"Flip")
      end
    end
  },
  [7] = {
    name = "Edit slot data...",
    enabled = true,
    help = function()
      window.text"Change the slots used for the color currently equipped on the button you clicked with"
    end,
    func = function(button)
      assignColorSlots(tTool[button].color)
      sync({colorSlots = tBlueprint.colorSlots},"Colorslots load")
    end
  },
  [8] = {
    name = "Mark built",
    enabled = true,
    help = function()
      window.text"Marks the entire blueprint as built, meaning the turtle will not build any of the currently drawn blocks.\n\nClear break markers?"
    end,
    func = function()
      local curLayer = tTerm.scroll.layer
      local button, tRes = window.text(
        "Mark the entire blueprint as built. This means the turtle will not build it",
        {
          "Cancel",
          "Yes",
          "No"
        }
      )
      if button == "Yes" or button == "Ok" then
        tBlueprint:markBuilt(nil,nil,nil,nil,true)
        scroll()
        sync({blueprint = true,clearBreak = true},"Mark built")
      elseif button == "No" then
        tBlueprint:markBuilt()
        if tMode.builtRender then
          scroll()
        end
        sync({blueprint = true},"Mark built")
      end
    end
  },
  [9] = {
    name = "Mark unbuilt",
    enabled = true,
    help = function()
      window.text"Resets all build progress made on the blueprint, by marking every block as un-built"
    end,
    func = function()
      local curLayer = tTerm.scroll.layer
      local button, tRes = window.text(
        "Mark the entire blueprint as unbuilt. This will reset any progress the turtle has made",
        {
          "Cancel",
          "Ok"
        }
      )
      if button == "Ok" then
        tBlueprint:markUnbuilt()
        if tMode.builtRender then
          scroll()
        end
      end
      sync({blueprint = true},"Mark unbuilt")
    end
  },
  [10] = {
    name = "Check usage",
    enabled = true,
    help = function()
      window.text"Check the materials required to build a given layer range"
    end,
    func = function()
      local tSelection = {}
      for i=1,#tBlueprint do
        tSelection[i] = {
          text = tostring(i),
          selected = true
        }
      end
      local button, tRes = window.scroll(
        "Select layers to check usage for",
        tSelection,
        true
      )
      if button ~= "Cancel" then
        local tLayers = {}
        for i,v in ipairs(tRes) do
          tLayers[i] = tonumber(v)
        end
        local tLines = {
          [1] = "Materials required to build current blueprint"
        }
        for k,v in pairs(checkUsage(tBlueprint,tLayers)) do
          tLines[#tLines+1] = (keyColor[k] or k)..": "..v
        end
        window.text(tLines)
      end
    end
  },
}
return menu