local fileTable
fileTable = { --file table class, this is used to simplify file handling
  new = function(path)
    local file = {}
    setmetatable(
      file,
      {
        __index = fileTable
      }
    )
    if path then
      file:load(path)
    end
    return file
  end,
  load = function(tTable,filePath)
    --loads the specified file into the table
    local file = fs.open(filePath,"r")
    for line in file.readLine do
      tTable[#tTable+1] = line
    end
    tTable.path = filePath
    file.close()
  end,
  save = function(tTable,filePath)
    --saves the current table to the specified filePath
    local file = fs.open(filePath or tTable.path,"w")
    file.write(table.concat(tTable,"\n"))
    file.close()
  end,
  insert = function(tTable,line,lineNum)
    --inserts the specified line into the table, optionally at the specified lineNum
    lineNum = lineNum or #tTable+1
    if type(line) == "table" then
      for i=1,#line do
        table.insert(tTable,line[i],lineNum+i-1)
      end        
    else
      table.insert(tTable,line,lineNum)
    end
  end,
  write = function(tTable,line,lineNum)
    --write the specified line to the table, optionally at the specified lineNum
    lineNum = lineNum or #tTable+1
    if type(line) == "table" then
      for i=1,#line do
        tTable[lineNum+i-1] = line[i]
      end
      return
    end
    while line:match"\n." do --multi line
      local newLine = line:match"^(.-)\n"
      line = line:sub(#newLine+2)
      tTable[lineNum] = newLine
      lineNum = lineNum+1
    end
    tTable[lineNum] = line
  end,
  find = function(tTable,sString,plain)
    --finds the specified string in the file
    for i=1,#tTable do
      if tTable[i]:find(sString,nil,plain) then
        return i
      end
    end
    return false
  end,
  delete = function(tTable,lineNum)
    --clears the last line, or optionally the specified lineNum
    if lineNum then
      table.remove(tTable,lineNum)
    else
      tTable[#tTable] = nil
    end
  end,
  read = function(tTable,lineNum)
    --returns the last line, or optionally the specified lineNum
    return tTable[lineNum or #tTable]
  end,
  readAll = function(tTable) --returns all lines as a single string, with newline characters.
    return table.concat(tTable,"\n")
  end
}
return fileTable