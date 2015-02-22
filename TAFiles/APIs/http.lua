http = setmetatable(
  {
    paste = {
      get = function(code,file)
        local paste
        local response = http.get("http://pastebin.com/raw.php?i="..code)
        if response then
        --sucesss
          if file == true then
            --save to table
            local tLines = {}
            local line = response.readLine()
            while line do
              tLines[#tLines+1] = line
              line = response.readLine()
            end
            return tLines
          elseif file then
            --save to file
            local paste = response.readAll()
            response.close()
            local file = fs.open(file,"w")
            file.write(paste)
            file.close()
            return true
          else
            --save to variable
            local paste = response.readAll()
            response.close()
            return paste
          end
        else
          --failure
          return false
        end
      end,
      put = function(file,name)
        local upload
        if type(file) == "string" and fs.exists(file) then
        --local file
          file = fs.open("file","r")
          upload = file.readAll()
          file.close()
        elseif type(file) == "table" then
        --blueprint
          upload = file:save(true)
        end
        local key = tPaste.key
        local response = http.post(
          "http://pastebin.com/api/api_post.php",
          "api_option=paste&"..
          "api_dev_key="..key.."&"..
          "api_paste_format=text&"..
          "api_paste_name="..textutils.urlEncode(name or "Untitled").."&"..
          "api_paste_code="..textutils.urlEncode(upload)
        )
        if response then
        --sucess
          local sResponse = response.readAll()
          response.close()      
          local sCode = string.match( sResponse, "[^/]+$" )
          return sResponse, sCode
        else
          --failure
          return false
        end
      end
    }
  },
  {
    __index = _G.http
  }
)