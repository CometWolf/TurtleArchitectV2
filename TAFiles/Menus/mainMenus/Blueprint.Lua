local menu
menu = {
  [1] = {
    name = "Create new...",
    enabled = true,
    func = function()
      local button, tRes, reInput = input(
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
          button,tRes,reInput = reInput("Invalid file name!")
        elseif fs.exists(fileName..".TAb") then
          button,tRes,reInput = reInput(fileName.." already exists!")
        else
          tBlueprint = class.blueprint.new()
          tFile.blueprint = fileName
          scroll(1)
          input("Successfully created "..fileName..".TAb.")
          return
        end
      end
    end
  },
  [2] = {
    name = "Load...",
    enabled = true,
    func = function()
      local button, tRes, reInput = input(
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
            button,tRes,reInput = reInput("Missing pastebin code parameter!")
          else
            fileName = fileName:match"[^/]+"
            local paste = http.paste.get(fileName,true)
            if not paste then
              button,tRes,reInput = reInput("Pastebin download of "..fileName.." failed!")
            else
              local blueprint = tBlueprint.load(paste)
              if not blueprint then
                button,tRes,reInput = reInput(fileName.." was not a Turtle Architect file!")
              else
                tBlueprint = blueprint
                scroll()
                input("Successfully downloaded "..fileName.."!")
                return
              end
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
            input("Successfully loaded "..fileName..".TAb.")
            return
          end
        end
      end
    end
  },
  [3] = {
    name = "Save",
    enabled = true,
    func = function()
      local fileName = tFile.blueprint
      local button,tRes
      if not fileName then
        button, tRes = input(
          "No file name for current blueprint,",
          {
            "Cancel",
            "Ok"
          },
          {
            {
              name = "File name",
              value = "/",
              accepted = "."
            },
          }
        )
      end
      while button and button ~= "Cancel" do
        fileName = fileName or tRes["File name"]
        if not fileName then
          button,tRes,reInput = reInput("Invalid file name!")
        elseif fs.exists(fileName..".TAb") then
          button,tRes,reInput = reInput(fileName.." already exists!")
        else
          break
        end
      end
      tBlueprint:save(fileName)
      tFile.blueprint = fileName
      scroll()
      input("Successfully saved "..fileName..".TAb.")
    end
  },
  [4] = {
    name = "Save as...",
    enabled = true,
    func = function()
      local button, tRes = input(
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
        }
      )
      while button ~= "Cancel" do
        local fileName = fileName or tRes["File name"]
        if not fileName then
          button,tRes,reInput = reInput("Invalid file name!")
        elseif button == "Pastebin" then
          local response,code = http.paste.put(tBlueprint,fileName)
          if not code then
            button,tRes,reInput = reInput("Pastebin upload failed!")
          else
            input("Sucsessfully uploaded the blueprint to pastebin!\nCode: "..code.." \nURL: "..response)
            return
          end
        elseif fs.exists(fileName..".TAb") then
          button,tRes,reInput = reInput(fileName.." already exists!")
        else
          tBlueprint:save(fileName)
          tFile.blueprint = fileName
          scroll()
          input("Successfully saved "..fileName..".TAb.")
          return
        end
      end
    end
  },
  [5] = {
    name = "Send...",
    enabled = true and modem,
    func = function()
      
    end
  },
  [6] = {
    name = "Flip...",
    enabled = true,
    func = function()
      local button = input(
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
      elseif button == "Vertical" then
        tBlueprint:flipZ()
        scroll()
      end
    end
  },
  [7] = {
    name = "Edit slot data...",
    enabled = true,
    func = function(button)
      assignColorSlots(tTool[button].color)
    end
  },
  [8] = {
    name = "Mark built",
    enabled = true,
    func = function()
      local curLayer = tTerm.scroll.layer
      local button, tRes = input(
        "Mark the entire blueprint as built. This means the turtle will not build it",
        {
          "Cancel",
          "Ok"
        }
      )
      if button == "Ok" then
        tBlueprint:markBuilt()
        if tMode.builtRender then
          scroll()
        end
      end
    end
  },
  [9] = {
    name = "Mark unbuilt",
    enabled = true,
    func = function()
      local curLayer = tTerm.scroll.layer
      local button, tRes = input(
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
    end
  },
  [10] = {
    name = "Check usage",
    enabled = true,
    func = function()
      local button, tRes = input(
        "Check material requirements for the layer range",
        {
          "Cancel",
          "Ok"
        },
        {
          {
            name = "From",
            value = 1,
            accepted = "%d"
          },
          {
            name = "To",
            value = #tBlueprint,
            accepted = "%d"
          },
        }
      )
      while button ~= "Cancel" do
        if not tRes.From then
          button,tRes,reInput = reInput("Missing parameter From!")
        elseif not tRes.To then
          button,tRes,reInput = reInput("Missing parameter To!")
        elseif not tBlueprint[tRes.From]
        or not tBlueprint[tRes.To] then
          button,tRes,reInput = reInput("Invalid slot range "..tRes.From.."-"..tRes.To)
        else
          local tLines = {
            [1] = "Materials required to build current blueprint"
          }
          for k,v in pairs(checkUsage(tBlueprint,tRes.From,tRes.To)) do
            tLines[#tLines+1] = (keyColor[k] or k)..": "..v
          end
          input(tLines)
          return
        end
      end
    end
  },
}
return menu