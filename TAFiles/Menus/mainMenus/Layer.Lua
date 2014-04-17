local menu
menu = {
  [1] = {
    name = "Create new...",
    func = function()
      local button, tRes = input(
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
        }
      )
      while button ~= "Cancel" do
        local newLayer = tRes["New layer"]
        while #tBlueprint < newLayer do
          tBlueprint[#tBlueprint+1] = class.layer:new()
        end
        tTerm.scroll.layer = newLayer
        scroll()
        return
      end
    end
  },
  [2] = {
    name = "Import...",
    func = function()
      local button, tRes, reInput = input(
        "Import layers from another blueprint",
        {
          "Cancel",
          "Ok"
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
        local iBlueprint = loadBlueprint(tRes.Blueprint)
        if not fs.exists(tRes.Blueprint) then
          button,tRes,reInput = reinput(tRes.Blueprint.." does not exist!")
        elseif not iBlueprint then
          button,tRes,reInput = reInput(tRes.Blueprint.." is not a blueprint file!")
        elseif not iBlueprint[tRes.From] then
          button,tRes,reInput = reInput("The layer "..tRes.From.." does not exist in the blueprint "..tRes.Blueprint.."!")
        elseif not iBlueprint[tRes.To] then
          button,tRes,reInput = reInput("The layer "..tRes.To.." does not exist in the blueprint "..tRes.Blueprint.."!")
        elseif tBlueprint[tRes.Into] then
          local button2 = input(
            "Layers already exist in the range "..tRes.Into.."-"..tRes.Into+(tRes.To-tRes.From).." in the current blueprint!",
            {
              "Cancel",
              "Overwrite",
              "Insert"
            }
          )
          button = (button2 == "cancel") and "Reinput" or button2
        elseif button == "Ok"
        or button == "Overwrite" then
          while #tBlueprint < tRes.Into do
            tBlueprint[#tBlueprint+1] = class.layer:new()
          end
          for i=tRes.From,tRes.To do
            local layer = tRes.Into+i-tRes.From
            tBlueprint[layer] = iBlueprint[i]:copy()
          end
          scroll()
          return
        elseif button == "Insert" then
          while #tBlueprint < tRes.Into do
            tBlueprint[#tBlueprint+1] = class.layer:new()
          end
          for i=tRes.From,tRes.To do
            local layer = tRes.Into+i-tRes.From
            table.insert(tBlueprint,iBlueprint[i]:copy(),layer)
          end
          scroll()
          return
        end
      end
    end
  },
  [3] = {
    name = "Delete current",
    func = function()
      local delLayer = tTerm.scroll.layer
      local button, tRes = input(
        "Are you sure you wish to delete layer "..delLayer.."?",
        {
          "Cancel",
          "Ok"
        }
      )
      while button ~= "Cancel" do
        if delLayer == 1 and #tBlueprint == 1 then
          tBlueprint[1] = tBlueprint[1]:new()
        else
          table.remove(tBlueprint,delLayer)
        end
        tTerm.scroll.layer = math.max(tTerm.scroll.layer-1,1)
        scroll()
        return
      end
    end
  },
  [4] = {
    name = "Delete range...",
    func = function()
      local button, tRes = input(
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
        }
      )
      while button ~= "Cancel" do
        for i=tRes.From,tRes.To do
          table.remove(tBlueprint,tRes.From)
        end
        tTerm.scroll.layer = math.min(tTerm.scroll.layer,#tBlueprint)
        scroll()
        return
      end
    end
  },
  [5] = {
    name = "Move to...",
    func = function()
      local curLayer = tTerm.scroll.layer
      local button, tRes, reInput = input(
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
        if tBlueprint[tRes.To] then
          local button2 = input(
            "The layer "..tRes.To.." already exists!",
            {
              "Cancel",
              "Overwrite",
              "Insert",
            }
          )
          button = (button2 == "Cancel") and "Reinput" or button2
        elseif button == "Ok"
        or button == "Overwrite" then
          while #tBlueprint < tRes.To do
            tBlueprint[#tBlueprint+1] = class.layer:new()
          end
          tBlueprint[tRes.To] = tBlueprint[curLayer]:copy()
          tBlueprint[curLayer] = class.layer.new()
          scroll()
          return
        elseif button == "Insert" then
          while #tBlueprint < tRes.To do
            tBlueprint[#tBlueprint+1] = class.layer:new()
          end
          table.insert(tBlueprint, tBlueprint[curLayer]:copy(), tRes.To)
          tBlueprint[curLayer] = class.layer.new()
          scroll()
          return
        end
      end
    end
  },
  [6] = {
    name = "Move range...",
    func = function()
      local button, tRes, reInput = input(
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
        if tBlueprint[tRes.Into] then
          local button2 = input(
            "Layers already exist in the range "..tRes.Into.."-"..tRes.Into+(tRes.To-tRes.From).."!",
            {
              "Cancel",
              "Overwrite",
              "Insert"
            }
          )
          button = (button2 == "cancel") and "Reinput" or button2
        elseif button == "Ok"
        or button == "Overwrite" then
          while #tBlueprint < tRes.Into do
            tBlueprint[#tBlueprint+1] = class.layer:new()
          end
          for i=tRes.From,tRes.To do
            local layer = tRes.Into+i-tRes.From
            tBlueprint[layer] = tBlueprint[i]:copy()
            tBlueprint[i] = class.layer.new()
          end
          scroll()
          return
        elseif button == "Insert" then
          while #tBlueprint < tRes.Into do
            tBlueprint[#tBlueprint+1] = class.layer:new()
          end
          for i=tRes.From,tRes.To do
            local layer = tRes.Into+i-tRes.From
            table.insert(tBlueprint,iBlueprint[i]:copy(),layer)
            tBlueprint[i] = class.layer.new()
          end
          scroll()
          return
        end
      end
    end
  },
  [7] = {
    name = "Copy to...",
    func = function()
      local curLayer = tTerm.scroll.layer
      local button, tRes, reInput = input(
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
        if tBlueprint[tRes.To] then
          local button2 = input(
            "The layer "..tRes.To.." already exists!",
            {
              "Cancel",
              "Overwrite",
              "Insert",
            }
          )
          button = (button2 == "Cancel") and "Reinput" or button2
        elseif button == "Ok"
        or button == "Overwrite" then
          while #tBlueprint < tRes.To-1 do
            tBlueprint[#tBlueprint+1] = class.layer:new()
          end
          tBlueprint[tRes.To] = tBlueprint[curLayer]:copy()
          return
        elseif button == "Insert" then
          while #tBlueprint < tRes.To-1 do
            tBlueprint[#tBlueprint+1] = class.layer:new()
          end
          table.insert(tBlueprint, tBlueprint[curLayer]:copy(), tRes.To)
          return
        end
      end
    end
  },
  [8] = {
    name = "Stretch copy...",
    func = function()
      local button, tRes, reInput = input(
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
        if tBlueprint[tRes.From] and button == "Ok" then
          local button2 = input(
            "Layers already exist in the range "..tRes.From.."-"..tRes.To.."!",
            {
              "Cancel",
              "Overwrite",
              "Insert"
            }
          )
          button = (button2 == "Cancel") and "Reinput" or button2
        elseif button == "Ok"
        or button == "Overwrite" then
          while #tBlueprint < tRes.From do
            tBlueprint[#tBlueprint+1] = class.layer:new()
          end
          for i=tRes.From,tRes.To do
            tBlueprint[i] = tBlueprint[tTerm.scroll.layer]:copy()
          end
          scroll()
          return
        elseif button == "Insert" then
          while #tBlueprint < tRes.From do
            tBlueprint[#tBlueprint+1] = class.layer:new()
          end
          for i=tRes.From,tRes.To do
            table.insert(tBlueprint,tBlueprint[tTerm.scroll.layer]:copy(),i)
          end
          scroll()
          return
        end
      end
    end
  },
  [9] = {
    name = "Copy range...",
    func = function()
      local button, tRes, reInput = input(
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
        if tBlueprint[tRes.Into] then
          local button2 = input(
            "Layers already exist in the range "..tRes.Into.."-"..tRes.Into+(tRes.To-tRes.From).."!",
            {
              "Cancel",
              "Overwrite",
              "Insert"
            }
          )
          button = (button2 == "cancel") and "Reinput" or button2
        elseif button == "Ok"
        or button == "Overwrite" then
          while #tBlueprint < tRes.Into do
            tBlueprint[#tBlueprint+1] = class.layer:new()
          end
          for i=tRes.From,tRes.To do
            local layer = tRes.Into+i-tRes.From
            tBlueprint[layer] = tBlueprint[i]:copy()
          end
          scroll()
          return
        elseif button == "Insert" then
          while #tBlueprint < tRes.Into do
            tBlueprint[#tBlueprint+1] = class.layer:new()
          end
          for i=tRes.From,tRes.To do
            local layer = tRes.Into+i-tRes.From
            table.insert(tBlueprint,tBlueprint[i]:copy(),layer)
          end
          scroll()
          return
        end
      end
    end
  },
  [10] = {
    name = "Merge...",
    func = function()
      local button, tRes, reInput = input(
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
        for i=tRes.From+1,tRes.To do
          tBlueprint[tRes.From]:paste(tBlueprint[tRes.From+1])
          table.remove(tBlueprint,tRes.From+1)
        end
        scroll()
        return
      end
    end
  },
  [11] = {
    name = "Flip...",
    func = function()
      local curLayer = tTerm.scroll.layer
      local button = input(
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
      elseif button == "Vertical" then
        tBlueprint[curLayer] = tBlueprint[curLayer]:flipZ()
        scroll()
      end
    end
  },
  [12] = {
    name = "Mark built",
    func = function()
      local curLayer = tTerm.scroll.layer
      local button, tRes = input(
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
    end
  },
  [13] = {
    name = "Mark unbuilt",
    func = function()
      local curLayer = tTerm.scroll.layer
      local button, tRes = input(
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
    end
  },
  [14] = {
    name = "Goto...",
    func = function()
      local button, tRes = input(
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
          local button, tRes = input(
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