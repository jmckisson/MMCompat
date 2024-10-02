function MMCompat.procWord(str, n)
    local count = 0
    for word in str:gmatch("%S+") do
        count = count + 1
        if count == n then
            return word
        end
    end
    return ""
  end
  
  function MMCompat.procMath(params)
    local strMath = params:match("%S+")
  
    -- Check if strMath is empty
    if strMath == "" then
        MMCompat.warning("@Math() : Formula is empty.")
        return false
    end
  
    local lResult
    local isInteger = not strMath:find("%.")
    local strResult
  
    -- Try evaluating the math expression
    local func = loadstring("return " .. strMath)
    if func then
        local success, result = pcall(func)
        if success then
            lResult = result
            -- Format result based on the type
            if isInteger then
                strResult = string.format("%d", lResult)
            else
                strResult = string.format("%.4f", lResult)
            end
        else
          MMCompat.warning("# Error in Math Formula!")
          return false
        end
    else
      MMCompat.warning("# Error in Math Formula: " .. err)
      return false
    end
  
    return strResult
  end
  
  -- listName, item
  function MMCompat.procInList(listName, item)
    if not MMGlobals[listName] then
      MMCompat.warning("List " .. listName .. " does not exist")
      return "0"
    end
  
    if table.index_of(MMGlobals[listName], item) then
      return "1"
    end
  
    return "0"
  end
  
  
  function MMCompat.procAsc(str)
    -- Extract the first character from strParams
    local strChar = str:match("%S+") or ""
  
    if strChar == "" then
        MMCompat.warning("@Asc(): You must provide a character to examine.")
        return false
    end
  
    local c = strChar:sub(1, 1)
  
    -- Get the ASCII value of the character
    local nNum = string.byte(c)
  
    -- Ensure nNum is within the valid byte range
    if nNum < 0 then
        nNum = nNum + 256
    end
  
    return nNum
  end
  
  
  function MMCompat.procComma(str)
    -- Reverse the input string to process groups of 3 digits from the right
    local reversed = str:reverse()
    local commatized = {}
  
    -- Iterate over the reversed string, adding commas every three digits
    for i = 1, #reversed, 3 do
        -- Extract groups of three characters
        table.insert(commatized, reversed:sub(i, i + 2))
    end
  
    -- Join the groups with commas, reverse back to the original order, and return the result
    return table.concat(commatized, ","):reverse()
  end
  
  
  function MMCompat.procConnected()
    local host, port, isConnected = getConnectionInfo()
    return isConnected
  end
  
  
  function MMCompat.procDeComma(str)
    if not str or str == "" then
        MMCompat.warning("@DeComma(): Text string is empty.")
        return false
    end
  
    return str:gsub(",", "")
  end
  
  
  function MMCompat.procExists(varName)
    if not MMGlobals[varName] then
      return "0"
    end
  
    return "1"
  end
  
  function MMCompat.procFileExists(filePath)
    local file = io.open(filePath, "r")  -- Try to open the file in read mode
    if file then
        file:close()  -- Close the file if it was successfully opened
        return "1"
    else
        return "0"
    end
  end
  
  function MMCompat.procGetArray(name, row, col)
    if not MMGlobals[name] then
      MMCompat.warning("Array not found: " .. name)
      return "0"
    end
  
    if not MMGlobals[name][row] then
      MMCompat.warning("Index out of bounds: " .. row)
      return "0"
    end
  
    if not MMGlobals[name][row][col] then
      MMCompat.warning("Index out of bounds: " .. row)
      return "0"
    end
  
    return MMGlobals[name][row][col]
  end
  
  
  function MMCompat.procGetCount(listName)
    if not MMGlobals[listName] then
      MMCompat.warning("Cannot find list: " .. listName)
      return false
    end
  
    return #MMGlobals[listName]
  end
  
  
  function MMCompat.procGetItem(listName, item)
    if not listName or listName == "" then
      MMCompat.warning("List name is empty")
      return false
    end
  
    if not MMGlobals[listName] then
      MMCompat.warning("Cannot find list: " .. listName)
      return false
    end
  
    if not item or item == "" then
      MMCompat.warning("Item name is empty")
      return false
    end
  
    return MMGlobals[listName][item]
  end
  
  
  function MMCompat.procReplace(str, strOld, strNew)
    if not str or str == "" then
      MMCompat.warning("String is empty")
      return
    end
  
    if not strOld or strOld == "" then
      MMCompat.warning("strOld is empty")
      return
    end
  
    if not strNew or strNew == "" then
      MMCompat.warning("strNew is empty")
      return
    end
  
    return str:gsub(strOld, strNew)
  end
  
  
  function MMCompat.procVar(varName)
    if not varName or varName == "" then
      MMCompat.warning("Variable name is empty")
      return false
    end
  
    if not MMGlobals[varName] then
      MMCompat.warning("No variable by that name")
      return false
    end
  
    return MMGlobals[varName]
  end
  
  function MMCompat.procEventTime(eventName)
    if exists(eventName, "timer") == 0 then
      MMCompat.warning(string.format("No timer by the name '%s' exists", eventName))
      return false
    end
  
    if isActive(eventName, "timer") == 0 then
      MMCompat.warning(string.format("Timer '%s' is not active", eventName))
      return false
    end
  
    return remainingTime(eventName)
  end