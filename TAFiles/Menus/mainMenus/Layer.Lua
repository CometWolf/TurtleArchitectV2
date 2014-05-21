local menu
menu = {
  enabled = true,
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
          button,tRes,reInput = rewindow.text("Missing layer parameter!")
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
          button,tRes,reInput = rewindow.text("Overwrite of "..newLayer.." Cancelled. Input new layer number")
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
        if not tRes.Blueprint then
          if button == "Pastebin" then
            button,tRes,reInput = rewindow.text("Pastebin code parameter missing!")
          else
            button,tRes,reInput = rewindow.text("Import blueprint parameter missing!")
          end
        else
          iBlueprint = button == "Pastebin" and tBlueprint.load(http.get(fileName,true)) or loadBlueprint(tRes.Blueprint)
          if button ~= "Pastebin" and not fs.exists(tRes.Blueprint) then
            button,tRes,reInput = rewindow.text(tRes.Blueprint.." does not exist!")
          elseif not iBlueprint then
            button,tRes,reInput = rewindow.text(tRes.Blueprint.." is not a blueprint file!")
          elseif not tRes.From then
            button,tRes,reInput = rewindow.text("From layer parameter missing!")
          elseif not iBlueprint[tRes.From] then
            button,tRes,reInput = rewindow.text("The layer "..tRes.From.." does not exist in the blueprint "..tRes.Blueprint.."!")
          elseif not tRes.To then
            button,tRes,reInput = rewindow.text("To layer parameter missing!")
          elseif not iBlueprint[tRes.To] then
            button,tRes,reInput = rewindow.text("The layer "..tRes.To.." does not exist in the blueprint "..tRes.Blueprint.."!")
          elseif not tRes.Into then
            button,tRes,reInput = rewindow.text("Into layer parameter missing!")
          elseif tBlueprint[tRes.Into] then
            local button2 = window.text(
              "Layers already exist in the range "..tRes.Into.."-"..tRes.Into+(tRes.To-tRes.From).." in the current blueprint!",
              {
                "Cancel",
                "Overwrite",
                "Insert"
              }
            )
            button = (button2 == "cancel") and "Rewindow.text" or button2
          elseif button == "Ok"
          or button == "Overwrite"
          or button == "Pastebin" then
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
          button,tRes,reInput = rewindow.text"Missing starting layer parameter!"
        elseif not to then
          button,tRes,reInput = rewindow.text"Missing to layer parameter!"
        elseif from > to
        or from < 1 then
          button,tRes,reInput = rewindow.text("Invalid layer range "..from.."-"..to)
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
          button,tRes,reInput = rewindow.text"Missing move to layer parameter!"
        elseif tRes.To < 1 then
          button,tRes,reInput = rewindow.text("Invalid layer number "..tRes.To)
        elseif tBlueprint[tRes.To] then
          local button2 = window.text(
            "The layer "..tRes.To.." already exists!",
            {
              "Cancel",
              "Overwrite",
              "Insert",
            }
          )
          button = (button2 == "Cancel") and "Rewindow.text" or button2
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
          button,tRes,reInput = rewindow.text"Missing starting layer parameter!"
        elseif not to then
          button,tRes,reInput = rewindow.text"Missing to layer parameter!"
        elseif from > to
        or from < 1 then
          button,tRes,reInput = rewindow.text("Invalid layer range "..from.."-"..to)
        elseif not tRes.Into then
          button,tRes,reInput = rewindow.text"Missing move into layer parameter!"
        elseif tRes.Into < 1 then
          button,tRes,reInput = rewindow.text("Invalid move to layer "..tRes.Into) 
        elseif tBlueprint[tRes.Into] then
          local button2 = window.text(
            "Layers already exist in the range "..tRes.Into.."-"..tRes.Into+(tRes.To-tRes.From).."!",
            {
              "Cancel",
              "Overwrite",
              "Insert"
            }
          )
          button = (button2 == "cancel") and "Rewindow.text" or button2
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
        if button == "Rewindow.text" then
          button, tRes, reInput = rewindow.text("Copy current layer("..curLayer..")")
        elseif not tRes.To then
          button,tRes,reInput = rewindow.text"Missing copy to layer parameter!"
        elseif tRes.To < 1 then
          button,tRes,reInput = rewindow.text("Invalid copy to layer "..tRes.To)
        elseif button == "Ok" and tBlueprint[tRes.To] then
          local button2 = window.text(
            "The layer "..tRes.To.." already exists!",
            {
              "Cancel",
              "Overwrite",
              "Insert",
            }
          )
          button = (button2 == "Cancel") and "Rewindow.text" or button2
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
          button,tRes,reInput = rewindow.text"Missing starting layer parameter!"
        elseif not to then
          button,tRes,reInput = rewindow.text"Missing to layer parameter!"
        elseif from > to
        or from < 1 then
          button,tRes,reInput = rewindow.text("Invalid layer range "..from.."-"..to)
        elseif tBlueprint[tRes.From] and button == "Ok" then
          local button2 = window.text(
            "Layers already exist in the range "..tRes.From.."-"..tRes.To.."!",
            {
              "Cancel",
              "Overwrite",
              "Insert"
            }
          )
          button = (button2 == "Cancel") and "Rewindow.text" or button2
          if button == "Rewindow.text" then
            button,tRes,reInput = rewindow.text("Stretch copy current layer("..tTerm.scroll.layer..") across")
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
        if button == "Rewindow.text" then
          button,tRes,reInput = rewindow.text"Copy layer range"
        elseif not from then
          button,tRes,reInput = rewindow.text"Missing starting layer parameter!"
        elseif not to then
          button,tRes,reInput = rewindow.text"Missing to layer parameter!"
        elseif from > to
        or from < 1 then
          button,tRes,reInput = rewindow.text("Invalid layer range "..from.."-"..to)
        elseif not tRes.Into then
          button,tRes,reInput = rewindow.text"Missing copy into layer parameter!"
        elseif tRes.Into < 1 then
          button,tRes,reInput = rewindow.text("Invalid copy to layer "..tRes.Into) 
        elseif button == "Ok" and tBlueprint[tRes.Into] then
          local button2 = window.text(
            "Layers already exist in the range "..tRes.Into.."-"..tRes.Into+(tRes.To-tRes.From).."!",
            {
              "Cancel",
              "Overwrite",
              "Insert"
            }
          )
          button = (button2 == "Cancel") and "Rewindow.text" or button2
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
          button,tRes,reInput = rewindow.text"Missing starting layer parameter!"
        elseif not to then
          button,tRes,reInput = rewindow.text"Missing to layer parameter!"
        elseif from > to
        or from < 1 then
          button,tRes,reInput = rewindow.text("Invalid layer range "..from.."-"..to)
        elseif not tBlueprint[to] then
          button,tRes,reInput = rewindow.text("Non-existant layer range "..from.."-"..to..".\nCurrent top layer: "..#tBlueprint)
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
        sync({dir = "X"},"Flip")
      elseif button == "Vertical" then
        tBlueprint[curLayer] = tBlueprint[curLayer]:flipZ()
        scroll()
        sync({dir = "Z"},"Flip")
      end
    end
  },
  [12] = {
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
      end
      if tMode.builtRender then
        scroll()
      end
      sync({layer = curLayer},"Mark built")
    end
  },
  [13] = {
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
      end
      if tMode.builtRender then
        scroll()
      end
      sync({layer = curLayer},"Mark unbuilt")
    end
  },
  [14] = {
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
}
return menu