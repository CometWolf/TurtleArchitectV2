local menu
local layerBar = tBar.layerBar
menu = {
  [1] = {
    name = "Insert new above",
    enabled = function()
      return layerBar.selectedAmt == 1
    end,
    help = function()
      window.text"Inserts a new blank layer below the currently selected layer"
    end,
    func = function()
      local layer = layerBar.prevSelected+1
      table.insert(tBlueprint,layer,class.layer.new())
      renderLayerBar()
      sync({layer = layer},"Layer add")
    end
  },
  [2] = {
    name = "Insert new below",
    enabled = function()
      return layerBar.selectedAmt == 1
    end,
    help = function()
      window.text"Inserts a new blank layer below the currently selected layer"
    end,
    func = function()
      local layer = layerBar.prevSelected
      table.insert(tBlueprint,layer,class.layer.new())
      renderLayerBar()
      scroll(layer+1)
      sync({layer = layer},"Layer add")
    end
  },
  [3] = {
    name = "Import...",
    enabled = function()
      return layerBar.selectedAmt == 1
    end,
    help = function()
      window.text"Import layers from another blueprint into the layers above the one currently selected"
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
          else
            while #tBlueprint < tRes.Into do
              tBlueprint[#tBlueprint+1] = class.layer.new()
            end
            for i=tRes.From,tRes.To do
              local layer = tRes.Into+i-tRes.From
              table.insert(tBlueprint,iBlueprint[i]:copy(),layer)
            end
            scroll()
            sync({blueprint = tBlueprint,blueprintName = tFile.blueprint},"Blueprint load")
          end
        end
      end
    end
  },
  [4] = {
    name = "Delete",
    enabled = function()
      return layerBar.selectedAmt > 0
    end,
    help = function()
      window.text"Deletes the currently selected layers"
    end,
    func = function()
      local scrollLayer = tTerm.scroll.layer
      local delLayers = {}
      for layer in pairs(layerBar.tSelected) do
        delLayers[#delLayers+1] = layer
      end
      table.sort(
        delLayers,
        function(k1,k2)
          return k1 > k2
        end
      )
      for i,layer in ipairs(delLayers) do
        if layer == 1 and #tBlueprint == 1 then
          tBlueprint[1] = tBlueprint[1].new()
        else
          table.remove(tBlueprint,layer)
        end
        if scrollLayer >= layer then
          scrollLayer = scrollLayer-1
        end
      end
      sync({layers = layerBar.tSelected},"Layer delete")
      layerBar.tSelected = {
        [scrollLayer] = true
      }
      layerBar.prevSelected = scrollLayer
      layerBar.selectedAmt = 1
      renderLayerBar(true)
      scroll(math.max(scrollLayer,1))
    end
  },
  [5] = {
    name = "Clear",
    enabled = function()
      return layerBar.selectedAmt > 0
    end,
    help = function()
      window.text"Clears the currently selected layers"
    end,
    func = function()
      for layer in pairs(layerBar.tSelected) do
        tBlueprint[layer] = class.layer.new()
      end
      scroll()
      sync({layers = layerBar.tSelected},"Layer clear")
    end
  },
  [6] = {
    name = "Cut",
    enabled = function()
      return layerBar.selectedAmt > 0
    end,
    help = function()
      window.text"Move the currently selected layers"
    end,
    func = function()
      layerBar.clipboard = {}
      local cutLayers = {}
      for layer in pairs(layerBar.tSelected) do
        cutLayers[#cutLayers+1] = layer
      end
      table.sort(
        cutLayers,
        function(k1,k2)
          return k1 > k2
        end
      )
      local scrollLayer = tTerm.scroll.layer
      for i,layer in ipairs(cutLayers) do
        layerBar.clipboard[#cutLayers-i+1] = table.remove(tBlueprint,layer)
        if scrollLayer >= layer then
          scrollLayer = scrollLayer-1
        end
      end
      sync({layers = layerBar.tSelected},"Layer delete")
      layerBar.tSelected = {
        [scrollLayer] = true
      }
      layerBar.prevSelected = scrollLayer
      renderLayerBar(true)
      scroll(scrollLayer)
    end
  },
  [7] = {
    name = "Copy",
    enabled = true,
    help = function()
      window.text"Copy the currently selected layers"
    end,
    func = function()
      layerBar.clipboard = {}
      local copyOrder = {}
      for layer in pairs(layerBar.tSelected) do
        copyOrder[#copyOrder+1] = layer
      end
      table.sort(
        copyOrder,
        function(v1,v2)
          return v1 < v2
        end
      )
      for i,layer in ipairs(copyOrder) do
        layerBar.clipboard[i] = tBlueprint[layer]:copy()
      end
    end
  },
  [8] = {
    name = "Paste",
    enabled = function()
      return layerBar.clipboard and layerBar.selectedAmt == 1
    end,
    help = function()
      window.text"Paste the current clipboard above the currently selected layer"
    end,
    func = function()
      for i,layer in ipairs(layerBar.clipboard) do 
        table.insert(tBlueprint,layerBar.prevSelected+i,layer)
      end
      renderLayerBar()
      sync({blueprint = tBlueprint,blueprintName = tFile.blueprint},"Blueprint load")
    end
  },
  [9] = {
    name = "Merge",
    enabled = function()
      return layerBar.selectedAmt > 1
    end,
    help = function()
      window.text"Combine the selected layers into the bottom one"
    end,
    func = function()
      local mergeLayers = {}
      for layer in pairs(layerBar.tSelected) do
        mergeLayers[#mergeLayers+1] = layer
      end
      table.sort(
        mergeLayers,
        function(v1,v2)
          return v1 < v2
        end
      )
      local bottomLayer = table.remove(mergeLayers,1)
      local scrollLayer = tTerm.scroll.layer
      for i,layer in ipairs(mergeLayers) do
        tBlueprint[bottomLayer]:paste(tBlueprint[layer])
      end
      table.sort(
        mergeLayers,
        function(v1,v2)
          return v1 > v2
        end
      )
      for i,layer in ipairs(mergeLayers) do
        table.remove(tBlueprint,layer)
        if scrollLayer >= layer then
          scrollLayer = scrollLayer-1
        end
      end
      layerBar.tSelected = {
        [bottomLayer] = true
      }
      layerBar.selectedAmt = 1
      layerBar.prevSelected = bottomLayer
      renderLayerBar(true)
      if scrollLayer ~= tTerm.scroll.layer or scrollLayer == bottomLayer then
        scroll(scrollLayer,nil,nil,nil,true)
      end
      sync({blueprint = tBlueprint,blueprintName = tFile.blueprint},"Blueprint load")
    end
  },
  [10] = {
    name = "Select all",
    enabled = true,
    help = function()
      window.text"Selects all the layers in the blueprint"
    end,
    func = function()
      for layer=1,#tBlueprint do
        layerBar.tSelected[layer] = true
      end
      layerBar.selectedAmt = #tBlueprint
      renderLayerBar()
    end
  },
  [11] = {
    name = "Flip hori",
    enabled = function()
      return layerBar.selectedAmt > 0
    end,
    help = function()
      window.text"Flip the selected layers horizontally"
    end,
    func = function()
      for layer in pairs(layerBar.tSelected) do
        tBlueprint[layer] = tBlueprint[layer]:flipZ()
      end
      if layerBar.tSelected[tTerm.scroll.layer] then
        scroll()
      end
      sync({layers = layerBar.tSelected,dir = "X"},"Flip")
    end
  },
  [12] = {
    name = "Flip vert",
    enabled = function()
      return layerBar.selectedAmt > 0
    end,
    help = function()
      window.text"Flip the selected layers vertically"
    end,
    func = function()
      for layer in pairs(layerBar.tSelected) do
        tBlueprint[layer] = tBlueprint[layer]:flipZ()
      end
      if layerBar.tSelected[tTerm.scroll.layer] then
        scroll()
      end
      sync({layers = layerBar.tSelected,dir = "Z"},"Flip")
    end
  },
  [13] = {
    name = "Recolor",
    enabled = function()
      return layerBar.selectedAmt > 0
    end,
    help = function()
      window.text"Changes the color of the selected layers"
    end,
    func = function()
      local color = dialogue.selectColor("Recolor the selected layers to")
      if color ~= "Cancel" then
        for layer in pairs(layerBar.tSelected) do
          tBlueprint[layer]:recolor(colorKey[color])
        end
        if layerBar.tSelected[tTerm.scroll.layer] then
          scroll()
        end
        sync({layers = layerBar.tSelected,color = colorKey[color]},"Recolor")
      end
    end
  },
  [14] = {
    name = "Mark built",
    enabled = function()
      return layerBar.selectedAmt > 0
    end,
    help = function()
      window.text"Mark the entire current layer as built, meaning the turtle will skip it"
    end,
    func = function()
      for layer in pairs(layerBar.tSelected) do
        tBlueprint[layer]:markBuilt()
        if tMode.builtRender then
          scroll()
        end
      end
      if tMode.builtRender and layerBar.tSelected[tTerm.scroll.layer] then
        scroll()
      end
      sync({layers = layerBar.tSelected},"Mark built")
    end
  },
  [15] = {
    name = "Mark unbuilt",
    enabled = function()
      return layerBar.selectedAmt > 0
    end,
    help = function()
      window.text"Reset all build progress made on current layer"
    end,
    func = function()
      for layer in pairs(layerBar.tSelected) do
        tBlueprint[layer]:markUnbuilt()
      end
      if tMode.builtRender and layerBar.tSelected[tTerm.scroll.layer] then
        scroll()
      end
      sync({layers = layerBar.tSelected},"Mark unbuilt")
    end
  },
  [16] = {
    name = "Save as paint",
    enabled = function()
      return layerBar.selectedAmt == 1
    end,
    help = function()
      window.text"Saves the layer as a paint file"
    end,
    func = function()
      local button,tRes,reInput = window.text(
        "Input save path",
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
          local layer = tBlueprint[layerBar.prevSelected]
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
    name = "Close layer bar",
    enabled = true,
    help = function()
      window.text"Closes the layer bar and re-enables the layer menu"
    end,
    func = function()
      closeLayerBar()
      local file = class.fileTable.new(tFile.settings)
      local line = file:find("  layerBar = true,",true)
      file:write("  layerBar = false,",line)
      file:save()
    end
  },
}

return menu