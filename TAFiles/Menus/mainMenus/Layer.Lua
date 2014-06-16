local menu
menu = {
  enabled = function()
    return not tMode.layerBar
  end,
  [1] = {
    name = "Create new...",
    enabled = true,
    help = function()
      window.text"Creates a new blank layer"
    end,
    func = function()
      local button, tRes, reInput = window.text(
        "Create new layer...",
        {
          "Cancel",
          "Ok"
        },
        {
          {
            name = "New layer",
            value = string.format(#tBlueprint+1),
            accepted = "%d"
          }
        },
        false,
        true
      )
      while button ~= "Cancel" do
        local newLayer = tRes["New layer"]
        if not newLayer then
          button,tRes,reInput = reInput("Missing layer parameter!")
        elseif tBlueprint[newLayer] then
          button = window.text(
            "Layer "..newLayer.." already exists!\nOverwrite?",
            {
              "Cancel",
              "Overwrite"
            }
          )
          if button == "Overwrite" then
            break
          end
          button,tRes,reInput = reInput("Overwrite of "..newLayer.." Cancelled. Input new layer number")
        else
          break
        end
      end
      if button ~= "Cancel" then
        while #tBlueprint < newLayer do
          tBlueprint[#tBlueprint+1] = class.layer.new()
        end
        tTerm.scroll.layer = newLayer
        scroll()
        sync({layer = newLayer},"Layer add")
        return
      end
    end
  },
  [2] = {
    name = "Import...",
    enabled = true,
    help = function()
      window.text"Import layers from another blueprint into this one"
    end,
    func = function()
      local button, tRes, reInput = window.text(
        "Import layers from another blueprint",
        {
          "Cancel",
          "Ok",
          "Pastebin"
        },
        {
          {
            name = "Blueprint",
            value = "/",
            accepted = "."
          },
          {
            name = "From",
            value = 1,
            accepted = "%d"
          },
          {
            name = "To",
            value = 1,
            accepted = "%d"
          },
          {
            name = "Into",
            value = #tBlueprint+1,
            accepted = "%d"
          },
        },
        false,
        true
      )
      while button ~= "Cancel" do
        local iBlueprint
        local fileName = tRes.Blueprint
        if not fileName then
          if button == "Pastebin" then
            button,tRes,reInput = reInput"Pastebin code parameter missing!"
          else
            button,tRes,reInput = reInput"Import blueprint parameter missing!"
          end
        elseif not tRes.From then
          button,tRes,reInput = reInput"From layer parameter missing!"
        elseif not tRes.To then
          button,tRes,reInput = reInput"To layer parameter missing!"
        elseif not tRes.Into then
          button,tRes,reInput = reInput"Into layer parameter missing!"
        elseif button == "Pastebin" then
          local paste = {}
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
            iBlueprint = tBlueprint.load(paste)
            button = dlStatus
          end
        else
          iBlueprint = tBlueprint.load(fileName)
          if not fs.exists(fileName) then
            button,tRes,reInput = reInput(fileName.." does not exist!")
          else
            button = "Success"
          end
        end
        if button == "Success" then
          if not iBlueprint then
            button,tRes,reInput = reInput(fileName.." is not a blueprint file!")
          elseif not iBlueprint[tRes.To] then
            button,tRes,reInput = reInput("The layer "..tRes.To.." does not exist in the blueprint "..tRes.Blueprint.."!")
          elseif tBlueprint[tRes.Into] then
            local button2 = window.text(
              "Layers already exist in the range "..tRes.Into.."-"..tRes.Into+(tRes.To-tRes.From).." in the current blueprint!",
              {
                "Cancel",
                "Overwrite",
                "Insert"
              }
            )
            button = (button2 == "cancel") and reInput"Import layers from another blueprint" or button2
          elseif button == "Overwrite"
          or button == "Success" then
            while #tBlueprint < tRes.Into do
              tBlueprint[#tBlueprint+1] = class.layer.new()
            end
            for i=tRes.From,tRes.To do
              local layer = tRes.Into+i-tRes.From
              tBlueprint[layer] = iBlueprint[i]:copy()
            end
            scroll()
            sync({blueprint = tBlueprint,blueprintName = tFile.blueprint},"Blueprint load")
            return
          elseif button == "Insert" then
            while #tBlueprint < tRes.Into do
              tBlueprint[#tBlueprint+1] = class.layer.new()
            end
            for i=tRes.From,tRes.To do
              local layer = tRes.Into+i-tRes.From
              table.insert(tBlueprint,iBlueprint[i]:copy(),layer)
            end
            scroll()
            sync({blueprint = tBlueprint,blueprintName = tFile.blueprint},"Blueprint load")
            return
          end
        end
      end
    end
  },
  [3] = {
    name = "Delete current",
    enabled = true,
    help = function()
      window.text"Deletes the currently selected layer"
    end,
    func = function()
      local delLayer = tTerm.scroll.layer
      local button, tRes = window.text(
        "Are you sure you wish to delete layer "..delLayer.."?",
        {
          "Cancel",
          "Ok"
        }
      )
      while button ~= "Cancel" do
        if delLayer == 1 and #tBlueprint == 1 then
          tBlueprint[1] = tBlueprint[1].new()
        else
          table.remove(tBlueprint,delLayer)
        end
        tTerm.scroll.layer = math.max(tTerm.scroll.layer-1,1)
        scroll()
        sync({layer = delLayer},"Layer delete")
        return
      end
    end
  },
  [4] = {
    name = "Delete range...",
    enabled = true,
    help = function()
      window.text"Deletes a specified set of layers, aswell as moving any existant layers down to fill the gap"
    end,
    func = function()
      local button, tRes, reInput = window.text(
        "Delete layer range",
        {
          "Cancel",
          "Ok"
        },
        {
          {
            name = "From",
            value = tTerm.scroll.layer,
            accepted = "%d"
          },
          {
            name = "To",
            value = #tBlueprint,
            accepted = "%d"
          },
        },
        false,
        true
      )
      while button ~= "Cancel" do
        local from,to = tRes.From,tRes.To
        if not from then
          button,tRes,reInput = reInput"Missing starting layer parameter!"
        elseif not to then
          button,tRes,reInput = reInput"Missing to layer parameter!"
        elseif from > to
        or from < 1 then
          button,tRes,reInput = reInput("Invalid layer range "..from.."-"..to)
        else
          for i=tRes.From,tRes.To do
            if i == 1 and #tBlueprint == 1 then
              tBlueprint[1] = tBlueprint[1].new()
            else
              table.remove(tBlueprint,tRes.From)
            end
          end
          tTerm.scroll.layer = math.min(tTerm.scroll.layer,#tBlueprint)
          scroll()
          sync({from = tRes.From,to = tRes.To},"Layer delete")
          return
        end
      end
    end
  },
  [5] = {
    name = "Move to...",
    enabled = true,
    help = function()
      window.text"Move the currently selected layer"
    end,
    func = function()
      local curLayer = tTerm.scroll.layer
      local button, tRes, reInput = window.text(
        "Move current layer("..curLayer..")",
        {
          "Cancel",
          "Ok"
        },
        {
          {
            name = "To",
            value = curLayer,
            accepted = "%d"
          }
        },
        false,
        true
      )
      while button ~= "Cancel" do
        if not tRes.To then
          button,tRes,reInput = reInput"Missing move to layer parameter!"
        elseif tRes.To < 1 then
          button,tRes,reInput = reInput("Invalid layer number "..tRes.To)
        elseif tBlueprint[tRes.To] then
          local button2 = window.text(
            "The layer "..tRes.To.." already exists!",
            {
              "Cancel",
              "Overwrite",
              "Insert",
            }
          )
          button = (button2 == "Cancel") and "reinput" or button2
        elseif button == "Ok"
        or button == "Overwrite" then
          while #tBlueprint < tRes.To do
            tBlueprint[#tBlueprint+1] = class.layer.new()
          end
          tBlueprint[tRes.To] = tBlueprint[curLayer]:copy()
          tBlueprint[curLayer] = class.layer.new()
          scroll()
          sync({blueprint = tBlueprint,blueprintName = tFile.blueprint},"Blueprint load")
          return
        elseif button == "Insert" then
          while #tBlueprint < tRes.To do
            tBlueprint[#tBlueprint+1] = class.layer.new()
          end
          table.insert(tBlueprint, tBlueprint[curLayer]:copy(), tRes.To)
          tBlueprint[curLayer] = class.layer.new()
          scroll()
          sync({blueprint = tBlueprint,blueprintName = tFile.blueprint},"Blueprint load")
          return
        end
      end
    end
  },
  [6] = {
    name = "Move range...",
    enabled = true,
    help = function()
      window.text"Move a set of layers"
    end,
    func = function()
      local button, tRes, reInput = window.text(
        "Move layer range",
        {
          "Cancel",
          "Ok"
        },
        {
          {
            name = "From",
            value = tTerm.scroll.layer,
            accepted = "%d"
          },
          {
            name = "To",
            value = #tBlueprint,
            accepted = "%d"
          },
          {
            name = "Into",
            value = #tBlueprint+1,
            accepted = "%d"
          },
        },
        false,
        true
      )
      while button ~= "Cancel" do
        local from,to = tRes.From,tRes.To
        if not from then
          button,tRes,reInput = reInput"Missing starting layer parameter!"
        elseif not to then
          button,tRes,reInput = reInput"Missing to layer parameter!"
        elseif from > to
        or from < 1 then
          button,tRes,reInput = reInput("Invalid layer range "..from.."-"..to)
        elseif not tRes.Into then
          button,tRes,reInput = reInput"Missing move into layer parameter!"
        elseif tRes.Into < 1 then
          button,tRes,reInput = reInput("Invalid move to layer "..tRes.Into) 
        elseif tBlueprint[tRes.Into] then
          local button2 = window.text(
            "Layers already exist in the range "..tRes.Into.."-"..tRes.Into+(tRes.To-tRes.From).."!",
            {
              "Cancel",
              "Overwrite",
              "Insert"
            }
          )
          button = (button2 == "cancel") and "reinput" or button2
        elseif button == "Ok"
        or button == "Overwrite" then
          while #tBlueprint < tRes.Into do
            tBlueprint[#tBlueprint+1] = class.layer.new()
          end
          for i=tRes.From,tRes.To do
            local layer = tRes.Into+i-tRes.From
            tBlueprint[layer] = tBlueprint[i]:copy()
            tBlueprint[i] = class.layer.new()
          end
          scroll()
          sync({blueprint = tBlueprint,blueprintName = tFile.blueprint},"Blueprint load")
          return
        elseif button == "Insert" then
          while #tBlueprint < tRes.Into do
            tBlueprint[#tBlueprint+1] = class.layer.new()
          end
          for i=tRes.From,tRes.To do
            local layer = tRes.Into+i-tRes.From
            table.insert(tBlueprint,iBlueprint[i]:copy(),layer)
            tBlueprint[i] = class.layer.new()
          end
          scroll()
          sync({blueprint = tBlueprint,blueprintName = tFile.blueprint},"Blueprint load")
          return
        end
      end
    end
  },
  [7] = {
    name = "Copy to...",
    enabled = true,
    help = function()
      window.text"Make a copy of the currently selected layer"
    end,
    func = function()
      local curLayer = tTerm.scroll.layer
      local button, tRes, reInput = window.text(
        "Copy current layer("..curLayer..")",
        {
          "Cancel",
          "Ok"
        },
        {
          {
            name = "To",
            value = curLayer+1,
            accepted = "%d"
          }
        },
        false,
        true
      )
      while button ~= "Cancel" do
        if button == "reinput" then
          button, tRes, reInput = reInput("Copy current layer("..curLayer..")")
        elseif not tRes.To then
          button,tRes,reInput = reInput"Missing copy to layer parameter!"
        elseif tRes.To < 1 then
          button,tRes,reInput = reInput("Invalid copy to layer "..tRes.To)
        elseif button == "Ok" and tBlueprint[tRes.To] then
          local button2 = window.text(
            "The layer "..tRes.To.." already exists!",
            {
              "Cancel",
              "Overwrite",
              "Insert",
            }
          )
          button = (button2 == "Cancel") and "reinput" or button2
        elseif button == "Ok"
        or button == "Overwrite" then
          tBlueprint[tRes.To] = tBlueprint[curLayer]:copy()
          while #tBlueprint < tRes.To do
            tBlueprint[#tBlueprint+1] = class.layer.new()
          end
          sync({blueprint = tBlueprint,blueprintName = tFile.blueprint},"Blueprint load")
          return
        elseif button == "Insert" then
          table.insert(tBlueprint, tBlueprint[curLayer]:copy(), tRes.To)
          while #tBlueprint < tRes.To do
            tBlueprint[#tBlueprint+1] = class.layer.new()
          end
          sync({blueprint = tBlueprint,blueprintName = tFile.blueprint},"Blueprint load")
          return
        end
      end
    end
  },
  [8] = {
    name = "Stretch copy...",
    enabled = true,
    help = function()
      window.text"Make multiple copies of the currently selected layer"
    end,
    func = function()
      local button, tRes, reInput = window.text(
        "Stretch copy current layer("..tTerm.scroll.layer..") across",
        {
          "Cancel",
          "Ok"
        },
        {
          {
            name = "From",
            value = tTerm.scroll.layer,
            accepted = "%d"
          },
          {
            name = "To",
            value = #tBlueprint,
            accepted = "%d"
          },
        },
        false,
        true
      )
      while button ~= "Cancel" do
        local from,to = tRes.From,tRes.To
        if not from then
          button,tRes,reInput = reInput"Missing starting layer parameter!"
        elseif not to then
          button,tRes,reInput = reInput"Missing to layer parameter!"
        elseif from > to
        or from < 1 then
          button,tRes,reInput = reInput("Invalid layer range "..from.."-"..to)
        elseif tBlueprint[tRes.From] and button == "Ok" then
          local button2 = window.text(
            "Layers already exist in the range "..tRes.From.."-"..tRes.To.."!",
            {
              "Cancel",
              "Overwrite",
              "Insert"
            }
          )
          button = (button2 == "Cancel") and "reinput" or button2
          if button == "reinput" then
            button,tRes,reInput = reInput("Stretch copy current layer("..tTerm.scroll.layer..") across")
          end
        elseif button == "Ok"
        or button == "Overwrite" then
          for i=tRes.From,tRes.To do
            tBlueprint[i] = tBlueprint[tTerm.scroll.layer]:copy()
          end
          while #tBlueprint < tRes.From do
            tBlueprint[#tBlueprint+1] = class.layer.new()
          end
          scroll()
          sync({blueprint = tBlueprint,blueprintName = tFile.blueprint},"Blueprint load")
          return
        elseif button == "Insert" then
          for i=tRes.From,tRes.To do
            table.insert(tBlueprint,tBlueprint[tTerm.scroll.layer]:copy(),i)
          end
          while #tBlueprint < tRes.From do
            tBlueprint[#tBlueprint+1] = class.layer.new()
          end
          scroll()
          sync({blueprint = tBlueprint,blueprintName = tFile.blueprint},"Blueprint load")
          return
        end
      end
    end
  },
  [9] = {
    name = "Copy range...",
    enabled = true,
    help = function()
      window.text"Copy a set of layers"
    end,
    func = function()
      local button, tRes, reInput = window.text(
        "Copy layer range",
        {
          "Cancel",
          "Ok"
        },
        {
          {
            name = "From",
            value = tTerm.scroll.layer,
            accepted = "%d"
          },
          {
            name = "To",
            value = #tBlueprint,
            accepted = "%d"
          },
          {
            name = "Into",
            value = #tBlueprint+1,
            accepted = "%d"
          },
        },
        false,
        true
      )
      while button ~= "Cancel" do
        local from,to = tRes.From,tRes.To
        if button == "reinput" then
          button,tRes,reInput = reInput"Copy layer range"
        elseif not from then
          button,tRes,reInput = reInput"Missing starting layer parameter!"
        elseif not to then
          button,tRes,reInput = reInput"Missing to layer parameter!"
        elseif from > to
        or from < 1 then
          button,tRes,reInput = reInput("Invalid layer range "..from.."-"..to)
        elseif not tRes.Into then
          button,tRes,reInput = reInput"Missing copy into layer parameter!"
        elseif tRes.Into < 1 then
          button,tRes,reInput = reInput("Invalid copy to layer "..tRes.Into) 
        elseif button == "Ok" and tBlueprint[tRes.Into] then
          local button2 = window.text(
            "Layers already exist in the range "..tRes.Into.."-"..tRes.Into+(tRes.To-tRes.From).."!",
            {
              "Cancel",
              "Overwrite",
              "Insert"
            }
          )
          button = (button2 == "Cancel") and "reinput" or button2
        elseif button == "Ok"
        or button == "Overwrite" then
          while #tBlueprint < tRes.Into do
            tBlueprint[#tBlueprint+1] = class.layer.new()
          end
          for i=tRes.From,tRes.To do
            local layer = tRes.Into+i-tRes.From
            tBlueprint[layer] = tBlueprint[i]:copy()
          end
          scroll()
          sync({blueprint = tBlueprint,blueprintName = tFile.blueprint},"Blueprint load")
          return
        elseif button == "Insert" then
          while #tBlueprint < tRes.Into do
            tBlueprint[#tBlueprint+1] = class.layer.new()
          end
          for i=tRes.From,tRes.To do
            local layer = tRes.Into+i-tRes.From
            table.insert(tBlueprint,tBlueprint[i]:copy(),layer)
          end
          scroll()
          sync({blueprint = tBlueprint,blueprintName = tFile.blueprint},"Blueprint load")
          return
        end
      end
    end
  },
  [10] = {
    name = "Merge...",
    enabled = true,
    help = function()
      window.text"Combine a set of layers into 1"
    end,
    func = function()
      local button, tRes, reInput = window.text(
        "Merge layer range",
        {
          "Cancel",
          "Ok"
        },
        {
          {
            name = "From",
            value = tTerm.scroll.layer,
            accepted = "%d"
          },
          {
            name = "To",
            value = #tBlueprint,
            accepted = "%d"
          },
        },
        false,
        true
      )
      while button ~= "Cancel" do
        local from,to = tRes.From,tRes.To
        if not from then
          button,tRes,reInput = reInput"Missing starting layer parameter!"
        elseif not to then
          button,tRes,reInput = reInput"Missing to layer parameter!"
        elseif from > to
        or from < 1 then
          button,tRes,reInput = reInput("Invalid layer range "..from.."-"..to)
        elseif not tBlueprint[to] then
          button,tRes,reInput = reInput("Non-existant layer range "..from.."-"..to..".\nCurrent top layer: "..#tBlueprint)
        else
          for i=tRes.From+1,tRes.To do
            tBlueprint[tRes.From]:paste(tBlueprint[tRes.From+1])
            table.remove(tBlueprint,tRes.From+1)
          end
          scroll()
          sync({blueprint = tBlueprint,blueprintName = tFile.blueprint},"Blueprint load")
          return
        end
      end
    end
  },
  [11] = {
    name = "Flip...",
    enabled = true,
    help = function()
      window.text"Flip the currently selected layer horizontally or vertically"
    end,
    func = function()
      local curLayer = tTerm.scroll.layer
      local button = window.text(
        "Flip current layer",
        {
          "Cancel",
          "Horizontal",
          "Vertical"
        }
      )
      if button == "Horizontal" then
        tBlueprint[curLayer] = tBlueprint[curLayer]:flipX()
        scroll()
        sync({layer = curLayer,dir = "X"},"Flip")
      elseif button == "Vertical" then
        tBlueprint[curLayer] = tBlueprint[curLayer]:flipZ()
        scroll()
        sync({layer = curLayer,dir = "Z"},"Flip")
      end
    end
  },
  [12] = {
    name = "Recolor",
    enabled = true,
    help = function()
      window.text"Changes the color of the entire selected layer"
    end,
    func = function()
      local curLayer = tTerm.scroll.layer
      local color = dialogue.selectColor("Recolor the current layer("..curLayer..") to")
      if color ~= "Cancel" then
        tBlueprint[curLayer]:recolor(colorKey[color])
        scroll()
        sync({layer = curLayer},"Mark built")
      end
    end
  },
  [13] = {
    name = "Mark built",
    enabled = true,
    help = function()
      window.text"Mark the entire current layer as built, meaning the turtle will skip it"
    end,
    func = function()
      local curLayer = tTerm.scroll.layer
      local button, tRes = window.text(
        "Mark the current layer("..curLayer..") as built. This means the turtle will not build it",
        {
          "Cancel",
          "Ok"
        }
      )
      if button == "Ok" then
        tBlueprint[curLayer]:markBuilt()
        if tMode.builtRender then
          scroll()
        end
        sync({layer = curLayer},"Mark built")
      end
    end
  },
  [14] = {
    name = "Mark unbuilt",
    enabled = true,
    help = function()
      window.text"Reset all build progress made on current layer"
    end,
    func = function()
      local curLayer = tTerm.scroll.layer
      local button, tRes = window.text(
        "Mark the current layer("..curLayer..") as unbuilt. This will reset any progress the turtle has made on this layer",
        {
          "Cancel",
          "Ok"
        }
      )
      if button == "Ok" then
        tBlueprint[curLayer]:markUnbuilt()
        if tMode.builtRender then
          scroll()
        end
        sync({layer = curLayer},"Mark unbuilt")
      end
    end
  },
  [15] = {
    name = "Goto...",
    enabled = true,
    help = function()
      window.text"Scroll to given layer"
    end,
    func = function()
      local button, tRes = window.text(
        "Goto layer number...",
        {
          "Cancel",
          "Ok"
        },
        {
          {
            name = "Layer",
            value = string.format(tTerm.scroll.layer),
            accepted = "%d"
          }
        }
      )
      if button == "Ok" then
        local newLayer = tRes.Layer
        while not tBlueprint[newLayer] do
          local button, tRes = window.text(
            "The layer "..newLayer.." does not exist!\nCurrent top layer: "..#tBlueprint,
            {
              "Cancel",
              "Ok"
            },
            {
              {
                name = "Layer",
                value = string.format(tTerm.scroll.layer),
                accepted = "%d"
              }
            }
          )
          if button == "Cancel" then
            return
          end
          newLayer = tRes.Layer
        end
        scroll(newLayer,false,false,true)
      end
    end
  },
  [16] = {
    name = "save as paint",
    enabled = true,
    help = function()
      window.text"Saves the current layer as a paint file"
    end,
    func = function()
      local button,tRes,reInput = window.text(
        "Input save path for paint conversion of layer "..tTerm.scroll.layer,
        {
          "Cancel",
          "Ok"
        },
        {
          {
            name = "Path",
            value = "/"
          }
        },
        nil,
        true
      )
      while button ~= "Cancel" do
        if not tRes.Path or not tRes.Path:match"/[^/]+$" then
          button,tRes,reInput = reInput"Invalid path!"
        elseif fs.exists(tRes.Path) and button ~= "Overwrite" then
          local button2 = window.text(
            tRes.Path.." already exists!\nOverwrite?",
            {
              "Cancel",
              "Overwrite"
            }
          )
          if button2 == "Cancel" then
            button,tRes,reInput = reInput"Input save path"
          else 
            button = button2
          end
        else
          local file = class.fileTable.new(tRes.Path)
          local layer = tBlueprint[tTerm.scroll.layer]
          for nX = 1,layer:size("x") do
            local sX = ""
            for nZ,vZ in pairs(layer[nX]) do
              vZ = paintColors[vZ:lower()]
              if #sX < nZ then
                sX = sX..string.rep(" ",nZ-#sX-1)..vZ
              else
                sX = sX:sub(1,nZ-1)..vZ..sX:sub(nZ+1)
              end
            end
            file:write(sX,nX)
          end
          file:save()
          return
        end
      end
    end
  },
  [17] = {
    name = "Open layerbar",
    enabled = true,
    help = function()
      window.text"Opens the layer bar and disables the layer menu"
    end,
    func = function()
      openLayerBar()
      closeLayerBar()
      local file = class.fileTable.new(tFile.settings)
      local line = file:find("  layerBar = false,")
      file:write("  layerBar = true,",line)
      file:save()
    end
  }
}
return menu