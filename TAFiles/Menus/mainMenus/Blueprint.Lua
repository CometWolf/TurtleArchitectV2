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
          button,tRes,reInput = rewindow.text("Invalid file name!")
        elseif fs.exists(fileName..".TAb") then
          button,tRes,reInput = rewindow.text(fileName.." already exists!")
        else
          tBlueprint = class.blueprint.new()
          tFile.blueprint = fileName
          scroll(1)
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
            button,tRes,reInput = rewindow.text("Missing pastebin code parameter!")
          else
            fileName = fileName:match"[^/]+"
            local paste = http.paste.get(fileName,true)
            if not paste then
              button,tRes,reInput = rewindow.text("Pastebin download of "..fileName.." failed!")
            else
              local blueprint = tBlueprint.load(paste)
              if not blueprint then
                button,tRes,reInput = rewindow.text(fileName.." was not a Turtle Architect file!")
              else
                tBlueprint = blueprint
                scroll()
                sync({blueprint = tBlueprint,blueprintName = false},"Blueprint load")
                window.text("Successfully downloaded "..fileName.."!")
                return
              end
            end
          end
        else
          local blueprint = tBlueprint.load(fileName)
          if not fileName then
            button,tRes,reInput = rewindow.text("Missing blueprint file name parameter!")
          elseif not fs.exists(fileName..".TAb") then
            button,tRes,reInput = rewindow.text(fileName.." does not exist!")
          elseif not blueprint then
            button,tRes,reInput = rewindow.text(fileName.." is not a blueprint file!")
          elseif button == "Ok" then
            tFile.blueprint = fileName
            tBlueprint = blueprint
            scroll()
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
          button,tRes,reInput = rewindow.text("Invalid file name!")
        elseif button == "Pastebin" then
          local response,code = http.paste.put(tBlueprint,fileName)
          if not code then
            button,tRes,reInput = rewindow.text("Pastebin upload failed!")
          else
            window.text("Sucsessfully uploaded the blueprint to pastebin!\nCode: "..code.." \nURL: "..response)
            return
          end
        elseif fs.exists(fileName..".TAb") then
          button,tRes,reInput = rewindow.text(fileName.." already exists!")
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
      local button, tRes, reInput = window.text(
      "Transfer current blueprint via rednet",
        {
          "Cancel",
          "Ok",
          "All"
        },
        {
          {
            name = "Computer ID",
            value = os.getComputerID(),
            accepted = "%d",
            charLimit = 5
          },
        },
        false,
        true
      )
      while button ~= "Cancel" do
        local id = button ~= "All" and tRes["Computer ID"] or "All"
        if not id then
          button,tRes,reInput = rewindow.text"Missing receiver ID!"
        elseif button == "Ok"
        or button == "All" then
          rednet.send(id,"Init connection",
            {},
            function()
              rednet.send(id,"Blueprint transmission",
                {
                  blueprint = tBlueprint,
                  blueprintName = tFile.blueprint or "Untitled"
                }
              )
              window.text("Successfully sent the current blueprint to computer ID "..id)
            end,
            function()
              window.text("Failed to connect to computer ID "..id)
            end
          )
          return
        end
      end
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
      window.text"Marks the entire blueprint as built, meaning the turtle will not build any of the currently drawn blocks"
    end,
    func = function()
      local curLayer = tTerm.scroll.layer
      local button, tRes = window.text(
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
      local button, tRes = window.text(
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
          button,tRes,reInput = rewindow.text("Missing parameter From!")
        elseif not tRes.To then
          button,tRes,reInput = rewindow.text("Missing parameter To!")
        elseif not tBlueprint[tRes.From]
        or not tBlueprint[tRes.To] then
          button,tRes,reInput = rewindow.text("Invalid slot range "..tRes.From.."-"..tRes.To)
        else
          local tLines = {
            [1] = "Materials required to build current blueprint"
          }
          for k,v in pairs(checkUsage(tBlueprint,tRes.From,tRes.To)) do
            tLines[#tLines+1] = (keyColor[k] or k)..": "..v
          end
          window.text(tLines)
          return
        end
      end
    end
  },
}
return menu