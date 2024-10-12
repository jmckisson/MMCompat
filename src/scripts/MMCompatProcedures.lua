MMCompat.add_help('@Abs', [[
Format: @Abs(number)

Returns the absolute value of an number.
]])


MMCompat.add_help('@AnsiBold', [[
Format: @AnsiBold()

A string containing the ANSI code for bold.
]])


MMCompat.add_help('@AnsiReset', [[
Format: @AnsiReset()

A string containing the ANSI code for reset.
]])


MMCompat.add_help({'@AnsiRev', '@AnsiReverse'}, [[
Format: @AnsiRev(), @AnsiReverse

A string containing the ANSI code for reversing foreground with background
colour.
]])


MMCompat.add_help('@Asc', [[
Format: @Asc(character)

Pass in a character, it returns the ASCII value.

Example:

@Asc(A)
This would return 65.
]])
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


MMCompat.add_help({'@BackBlack', '@BackBlue', '@BackCyan', '@BackGreen',
                    '@BackMagenta', '@BackRed', '@BackWhite', '@BackYellow'}, [[
Format: @BackBlack(), @BackBlue(), @BackCyan(), @BackGreen(),
        @BackMagenta(), @BackRed(), @BackWhite(), @BackYellow()

A string containing the ANSI codes to set the background color.
]])


MMCompat.add_help('@BackColor', [[
Format: @BackColor(ColorIndex)

A string containing the ANSI codes to set the back color to the color identified
by the ColorIndex. ColorIndex can be any number between one and eight.
]])
function MMCompat.procBackColor(idx)

    local nIdx = tonumber(idx)

    if not nIdx then
        return ""
    end

    if nIdx < 1 or nIdx > 8 then
        return ""
    end

    return MMCompat.foreColorTable[nIdx]
end


MMCompat.add_help('@Backward', [[
Format: @BackWard(text)

Returns the specified text in reverse order.

Example:

@BackWard(test)
Would return "tset"
]])


MMCompat.add_help('@Chr', [[
Format: @Chr(number)

Chr works like the basic command Chr$. It returns the ascii equivalent of
the number.

   * number - Must be between 0 and 255.

Example:

@Chr(65)
This would return a capital A. @Chr(3) is a heart, etc...
]])


MMCompat.add_help('@Comma', [[
Format: @Comma(number)

Returns number with comma separators.
]])
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


MMCompat.add_help('@ConCat', [[
Format: @ConCat(text1,text2)

ConCat returns the concatenation of two text strings.

   * text1 - The text to be appended to.
   * text2 - The text to append to text1.

/var test @ConCat(This is, a test!)
Would place the string "This is a test!" in a variable called test.
]])


MMCompat.add_help('@Connected', [[
Format: @Connected()

Returns 1 if you have an active connection. Returns 0 if you don't.
]])
function MMCompat.procConnected()
    local host, port, isConnected = getConnectionInfo()

    if isConnected then
        return 1
    end

    return 0
end


MMCompat.add_help('@Day', [[
Format: @Day()

Returns the day number of the current date. Between 1 and 31.
]])
function MMCompat.procDay()
    return os.date("%A")
end


MMCompat.add_help('@DeComma', [[
Format: @Decomma(string)

Removes all the commas in the string. Variables may be used and thus intended
to remove commas from numbers this can even be used to concatenate a comma
separated list.

Example:

@Decomma(XoXoX,o,AA) returns XoAoXoAA
]])
function MMCompat.procDeComma(str)
    if not str or str == "" then
        MMCompat.warning("@DeComma(): Text string is empty.")
        return false
    end

    return str:gsub(",", "")
end


MMCompat.add_help('@EventTime', [[
Format: @EventTime(event name)

EventTime returns how many seconds are left in an event before it fires.
]])
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


MMCompat.add_help('@Exists', [[
Format: @Exists(var name)

Returns 1 if the variable exists, otherwise 0.

   * var name - The name of the variable to look for.
]])
function MMCompat.procExists(varName)
    if not MMGlobals[varName] then
        return 0
    end

    return 1
end


MMCompat.add_help('@FileExists', [[
Format: @FileExists(filename)

Returns 1 if the file exists, otherwise 0.

   * filename - The path and filename of the file to look for.
]])
function MMCompat.procFileExists(filePath)
    local file = io.open(filePath, "r")  -- Try to open the file in read mode
    if file then
        file:close()  -- Close the file if it was successfully opened
        return 1
    else
        return 0
    end
end


MMCompat.add_help({'@ForeBlack', '@ForeBlue', '@ForeCyan', '@ForeGreen',
                    '@ForeMagenta', '@ForeRed', '@ForeWhite', '@ForeYellow'}, [[
Format: @ForeBlack(), @ForeBlue(), @ForeCyan(), @ForeGreen(),
        @ForeMagenta(), @ForeRed(), @ForeWhite(), @ForeYellow()

A string containing the ANSI codes to set the forecolor.
]])


MMCompat.add_help('@ForeColor', [[
Format: @ForeColor(ColorIndex)

A string containing the ANSI codes to set the fore color to the color identified
by the ColorIndex. ColorIndex can be any number between one and fifteen.

A string containing the ANSI codes to set the forecolor to the color identified by the ColorIndex.
]])
function MMCompat.procForeColor(idx)

    MMCompat.debug(string.format("in ForeColor(%d)", idx))

    local nIdx = tonumber(idx)

    if not nIdx then
        MMCompat.debug("not a number")
        return ""
    end

    if nIdx < 1 or nIdx > 15 then
        MMCompat.debug("not in bounds")
        return ""
    end

    return MMCompat.foreColorTable[nIdx]
end


MMCompat.add_help({'@A', '@Arr', '@GetArray'}, [[
Format: @A(array name,row,column), @Arr(array name,row,column), @GetArray(array name,row,column)

GetArray returns the value of a cell in an array.

   * array name - The name of the array from which you want to get the cell
     value.
   * row - The row number of the array. This number must be between 1 and the
     number of rows you defined for the array.
   * column - The column number of the array. This number must be between 1
     and the numer of columns you defined for the array. This third parameter
     is required, even when using a single dimensional array. However, when
     using a single dimensional array, it is ignored.

Examples:

@GetArray(Targets,1,0)
If Targets is a single dimensional array the column parameter would be ignored
but it required to be there. This would return the value of the first row of
the array Targets.

@GetArray(Grid,2,4)
If Grid is a two dimensional array, this would return the value of the cell at
row 2, column 4.

@a is the same as @getarray or @arr
See /assign for assigning values and /array for defining arrays
]])
function MMCompat.procGetArray(name, row, col)
    -- try to find array in arrays savelist
    local arrayTbl = MMCompat.findArray(name, row, col)

    if not arrayTbl then
        MMCompat.warning("Array not found: " .. name)
        return 0
    end

    return arrayTbl['data'][row][col]
end


MMCompat.add_help('@GetArrayRows', [[
Format: @GetArrayRows(array name)
Format: @GetArrayRows(array number)

GetArrayRows returns the max number of rows dimensioned in an array.

   * array name - The name of the array which you want the row dimension.
   * array number - The number of the array which you want the row dimension.
]])
function MMCompat.procGetArrayRows(arrayName)
    arrayName = string.lower(arrayName)
    local arrayTbl = nil
    for k, v in pairs(MMCompat.save.arrays) do
      if string.lower(v.name) == arrayName then
        arrayTbl = v
        break
      end
    end

    if not arrayTbl then
        MMCompat.warning("Array not found: " .. arrayName)
        return 0
    end

    return arrayTbl.bounds.rows
end


MMCompat.add_help('@GetArrayCols', [[
Format: @GetArrayCols(array name)
Format: @GetArrayCols(array number)

GetArrayCols returns the max number of columns dimensioned in an array.

   * array name - The name of the array which you want the column dimension.
   * array number - The number of the array which you want the column dimension.
]])
function MMCompat.procGetArrayCols(arrayName)
    arrayName = string.lower(arrayName)
    local arrayTbl = nil
    for k, v in pairs(MMCompat.save.arrays) do
      if string.lower(v.name) == arrayName then
        arrayTbl = v
        break
      end
    end

    if not arrayTbl then
        MMCompat.warning("Array not found: " .. arrayName)
        return 0
    end

    return arrayTbl.bounds.cols
end


MMCompat.add_help('@GetCount', [[
Format: @GetCount(list name)
Format: @GetCount(list number)

GetCount returns the number of items in a list.

   * list name - The name of the list from which you want to get the number of
     items.
   * list number - The number of the list from which you want to get the number
     of items.
]])
function MMCompat.procGetCount(listName)

    local listTbl = MMCompat.findListByNameOrId(listName)

    if not listTbl then
        MMCompat.warning("Cannot find list: " .. listName)
        return false
    end

    return listTbl.count
end
  
  
MMCompat.add_help('@GetItem', [[
Format: @GetItem(list name,number)
Format: @GetItem(list number,number)

GetItem retrieves an item from a list by number.

   * list name - The name of the list from which you want to get an item
   * list number - The number of the list from which you want to get an item.
   * number - The number of the item you want to get.

Example:

@GetItem(Friends,1)
Assuming you had a list called friends, this would give you the first item in
that list.
]])
function MMCompat.procGetItem(listName, item)

    local listTbl = MMCompat.findListByNameOrId(listName)

    if not listTbl then
        MMCompat.warning("List does not exist")
        return false
    end

    if listTbl.count == 0 then
        MMCompat.warning("List is empty")
        return false
    end

    if not item or item == "" then
        MMCompat.warning("Item name is empty")
        return false
    end

    if not listTbl.data[item] then
        MMCompat.warning("Item does not exist in list")
        return false
    end

    return listTbl.data[item]
end


MMCompat.add_help('@Hour', [[
Format: @Hour()

Returns the hour of the current time. Between 0 and 23.
]])


MMCompat.add_help('@If', [[
Format: @IF(condition)

Evaluates the condition the same way as /if does but returns 1 if the result is
true and 0 if it is false.
]])
function MMCompat.procIf(str)
    local strText = str
    local foundCondition = false
    local stmt = ""

    foundCondition, stmt, strText = MMCompat.findStatement(strText)

    if not foundCondition then
        MMCompat.warning("Could not parse condition from statement")
        return "0"
    end

    local parsedCondition = "return " .. MMCompat.replaceVariables(stmt, false)

    local result = MMCompat.executeString(parsedCondition)

    if result then
        return "1"
    end

    return "0"
end


MMCompat.add_help('@InList', [[
Format: @InList(list name,item text)
Format: @InList(list number,item text)

Returns: 1 if the text is in the list, otherwise 0

InList determines if a specific text string is in a user defined list. InList
can be evaluated in an /if statement. While you can use the list number to
specify a list to search I don't recommend it. If you added a new list it
might change the number of the list are looking for.

   * list name - The name of the list you want to check.
   * list number - The number of the list you want to check.
   * item text - The item you want to search for in the list.

/if {@InList(Friends,Rand)} {say Rand is in the list.} {say Rand is not in
the list.}
If the word "Rand" is in the list called "Friends" the text "say Rand is in
the list." would be sent to the mud, else the other string would be.

/if {@InList(Friends,Rand) = 0} {say Rand is not in the list.}
Searches for the word "Rand" in the list "Friends" and if it is NOT found the
text "say Rand is not in the list." is sent to the mud.
]])
function MMCompat.procInList(listName, item)

    local listTbl = MMCompat.findListByNameOrId(listName)

    if not listTbl then
        MMCompat.warning("List " .. listName .. " does not exist")
        return 0
    end

    if table.index_of(listTbl.data, item) then
        return 1
    end

    return 0
end


MMCompat.add_help('@IP', [[
Format: @IP()

IP returns your IP address.
]])


MMCompat.add_help('@IsEmpty', [[
Format: @IsEmpty(var name)

Returns a 1 if the variable is empty, otherwise a 0.

   * var name - The name of the variable to check.
]])
function MMCompat.procIsEmpty(varName)

    if not MMGlobals[varName] then
        return 1
    end

    if MMGlobals[varName] == "" then
        return 1
    end

    return 0
end


MMCompat.add_help('@IsNumber', [[
Format: @IsNumber(text)

Returns 1 if the text passed in is all numbers. Otherwise it returns 0.
]])


MMCompat.add_help('@Left', [[
Format: @Left(text,number of characters)

Left returns a number of characters from the left side of a string.

   * text - The text you want to take the left hand portion of.
   * number of characters - Number of characters you want.

Example:

@Left(Arithon,3)
Would return the string "Ari". The 3 leftmost characters.
]])


MMCompat.add_help('@Len', [[
Format: @Len(text)

Len returns the number of characters in a string.

Example:

@Len(Arithon)
Would return 7.
]])


MMCompat.add_help('@Lower', [[
Format: @Lower(text)

Lower converts all the letters in the text to lower case.  This can be
useful when comparing items in a list or with an /if.

Examples:

/if {@Lower($Name) == "arithon"}

@InList(Spells,@Lower($1))
]])


MMCompat.add_help('@LTrim', [[
Format: @LTrim(text)

LTrim removes any spaces from the left side of a string.
]])


MMCompat.add_help('@Math', [[
Format: @Math(expression)

Returns the result of a math expression. The works the same way as /math, only
the value is not placed into a variable. See the help on math for more
information.
]])
function MMCompat.procMath(strMath)

    -- Check if strMath is empty
    if strMath == "" then
        MMCompat.warning("@Math() : Formula is empty.")
        return false
    end

    local lResult
    local isInteger = not strMath:find("%.")
    local strResult

    MMCompat.debug("strMath: "..strMath)

    local processedParams, anyMatches = MMCompat.referenceVariables(strMath, MMGlobals)

    MMCompat.debug("processedParams: "..processedParams)

    -- Try evaluating the math expression
    local func = loadstring("return " .. processedParams)
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
        MMCompat.warning("# Error in Math Formula: " .. processedParams)
        return false
    end

    return strResult
end


MMCompat.add_help('@Mid', [[
Format: @Mid(text,start character,number of characters)

Mid returns a portion of a string. You tell mid what character you want to
start at, and how many characters from that point on. Strings are zero based,
so if you want the very first character in a string the start character would
have to be zero.

   * text - Text string from which you want to grab a portion.
   *  start character - The character index of the first character to get.
   *  number of characters - The number of characters to get.

Examples:

@Mid(Arithon,0,3)
This will get you the same result as using a @Left(Arithon,3). The text "Ari"
would be returned.

@Mid(Arithon,2,4)
Would return the string "itho".
]])


MMCompat.add_help('@Minute', [[
Format: @Minute()

Returns the minutes of the current time. Between 0 and 59.
]])


MMCompat.add_help('@Month', [[
Format: @Month()

Returns the month number of the current date. Between 1 and 12.
]])


MMCompat.add_help('@NumActions', [[
Format: @NumActions()

Returns the number of actions you have defined.
]])


MMCompat.add_help('@NumAliases', [[
Format: @NumAliases()

Returns the number of aliases you have defined.
]])


MMCompat.add_help('@NumEvents', [[
Format: @NumEvents()

Returns the number of events you have defined.
]])


MMCompat.add_help('@NumGags', [[
Format: @NumGags()

Returns the number of gags you have defined.
]])


MMCompat.add_help('@NumHighlights', [[
Format: @NumHighlights()

Returns the number of highlights you have defined.
]])


MMCompat.add_help('@NumLists', [[
Format: @NumLists()

Returns the number of lists you have defined.
]])


MMCompat.add_help('@NumMacros', [[
Format: @NumMacros()

Returns the number of macros you have defined.
]])


MMCompat.add_help('@NumVariables', [[
Format: @NumVariables()

Returns the number of variables you have defined.
]])


MMCompat.add_help('@PadLeft', [[
Format: @PadLeft(text,character,number)

Returns a string padded on the left with a specific character.

   * text - Text to pad.
   * character - Character to use for padding.
   * number - number of pad characters to add.
]])


MMCompat.add_help('@PadRight', [[
Format: @PadRight(text,character,number)

Returns a string padded on the right with a specific character.

   * text - Text to pad.
   * character - Character to use for padding.
   * number - number of pad characters to add
]])


MMCompat.add_help('@PreTrans', [[
Format: @PreTrans(stuff to do)

Many commands in Mud Master translate variables and evaluate procedure when
the command is executed. An example of this is when you define a macro that
contains a variable -- when you press the macro key the variable gets
translated. Sometimes, however, you will want the macro to store the value of
that variable instead of the variable name itself. PreTrans allows you to
expand variables and evaluate procedures at the time the command is created.

Examples:

/macro {f1} {say $Var}
When the F1 key is press the variable gets translated.

/macro {f2} {say @PreTrans($Var)}
In this case, using PreTrans, the variable gets expanded when the macro is
created. If $Var="Bob" the macro created is essentially: /macro {f2} {say Bob}
]])


MMCompat.add_help('@ProcedureCount', [[
Format: @ProcedureCount()

Returns the current amount of total Procedures coded into MudMaster 2k6. This
will also show you every procedure.
]])


MMCompat.add_help('@Random', [[
Format: @Random(Max Number)

Random returns a number between 1 and Max Number.

Examples:

say @Random(100)
Would say a number between 1 and 100.

say @GetItem(Greetings,@Random(@GetCount(Greetings))) Rand!
If you had a list that contained a bunch of different greetings the above would
randomly select one to use.
]])


MMCompat.add_help('@Replace', [[
Format: @Replace(string,string,string)

Replaces all the instances of stringToReplace in string with ReplacementString
and returns the result. Variables may be used for any of the strings.

Examples:

@Replace(XoXoX,o,AA) returns XAAXAAX
]])
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


MMCompat.add_help('@Right', [[
Format: @Right(text,number of characters)

Right returns a number of characters from the right side of a string.

   * text - The text you want to take the left hand portion of.
   * number of characters - Number of characters you want.

Examples:

@Right(Arithon,3)
Would return the string "hon". The 3 rightmost characters.
]])


MMCompat.add_help('@RTrim', [[
Format: @RTrim(text)

RTrim removes any spaces from the right side of a string.
]])


MMCompat.add_help('@Second', [[
Format: @Second()

Returns the seconds of the current time. Between 0 and 59.
]])


MMCompat.add_help('@SessionName', [[
Format: @SessionName()

Returns the name of your current Profile Window.
]])


MMCompat.add_help('@SessionPath', [[
Format: @SessionPath()

Returns the directory used for your Profile.
]])


MMCompat.add_help('@StripAnsi', [[
Format: @StripAnsi(text)

Pass in some text and it returns the same text with all the ansi codes removed.
]])
function MMCompat.procStripAnsi(str)
    if not str or str == "" then
        return str
    end

    return str:gsub("\27%[[%d;]*m", "")
end


MMCompat.add_help('@StrStr', [[
Format: @StrStr(search in,search for)

StrStr searches for the occurrence of one string in another. It returns the 0
based index of where the string to search for starts in the other. If the search
for string is not found -1 is returned.

   * search in - The text you want to search.
   * search for - The text you want to search for.

Examples:

@StrStr(Arithon,it)
This would return 2.
]])
function MMCompat.procStrStr(str, search)
    return string.find(str, search)
end


MMCompat.add_help('@StrStrRev', [[
Format: @StrStrRev(search in,search for)

StrStrRev searches for the LAST occurrence of one string in another, starting
at the end and moving toward the beginning. It returns the 0 based index of where
the string to search for starts in the other. If the search for string is not
found -1 is returned.

   * search in - The text you want to search.
   * search for - The text you want to search for.

Examples:

@StrStrRev(Arithonhit,it)
This would return 8.
]])
function MMCompat.procStrStrRev(str, search)
    local last_pos = nil
    local search_len = #search
    local start_pos = 1

    while true do
        local found_at = string.find(str, search, start_pos, true)
        if not found_at then
            break
        end
        last_pos = found_at
        start_pos = found_at + 1
    end

    return last_pos
end


MMCompat.add_help('@SubStr', [[
Format: @SubStr(string,startCharIndex,endCharIndex)

SubStr returns a string which is a substring of the original starting from
the startCharIndex until the endCharIndex. The index is 0 based.
]])
function MMCompat.procSubStr(str, startIdx, stopIdx)
    return string.sub(str, startIdx-1, stopIdx-1)
end


MMCompat.add_help({'@Time', '@TimeToDay', '@TimeToDayOfWeek', '@TimeToHour', '@TimeToMinute',
                    '@TimeToMonth', '@TimeToSecond', '@TimeToYear'}, [[
@Time() - Returns the number of seconds elapsed since January 1, 1970. Time
   can be used to create your own online timers. If you put the result of
   @Time() in a variable, then later on get the value of time again, you can
   subtract them for the number of seconds elapsed. The value from @Time() is
   also used for all the functions below.

@TimeToDay(time value) - Returns the day of the month.

@TimeToDayOfWeek(time value) - Returns the day of the week. 0 = Sunday,
   6 = Saturday.

@TimeToHour(time value) - Returns the hour of the day.

@TimeToMinute(time value) - Returns the minute of the hour.

@TimeToMonth(time value) - Returns the month of the year.

@TimeToSecond(time value) - Returns the seconds of the minute.

@TimeToYear(time value) - Returns the year.
]])
function MMCompat.procTime()
    return string.format("%d", os.time())
end


function MMCompat.procTimeToDay(timeVal)
    return os.date("*t", timeVal).day
end


function MMCompat.procTimeToDayOfWeek(timeVal)
    local day_of_week = os.date("*t", timeVal).wday - 1
    if day_of_week == -1 then
        day_of_week = 6
    end
    return day_of_week
end


function MMCompat.procTimeToHour(timeVal)
    return os.date("*t", timeVal).hour
end


function MMCompat.procTimeToMinute(timeVal)
    return os.date("*t", timeVal).min
end


function MMCompat.procTimeToMonth(timeVal)
    return os.date("*t", timeVal).month
end


function MMCompat.procTimeToSecond(timeVal)
    return os.date("*t", timeVal).sec
end


function MMCompat.procTimeToYear(timeVal)
    return os.date("*t", timeVal).year
end


MMCompat.add_help('@Upper', [[
Format: @Upper(text)

Upper converts all the letters in the text to upper case.  This can be useful
when comparing items in a list or with an /if.

Examples:

/if {@Upper($Name) == "ARITHON"}

@InList(Spells,@Upper($1))
]])
function MMCompat.procUpper(str)
    return string.upper(str)
end


MMCompat.add_help('@Var', [[
Format: @Var(text)

Var returns the value of a variable named by the parameter text. This
procedure allows you to construct a variable name as a paramter then look up
the value of that variable. This is probably best explained by example.

Let's say you have a user defined list. In this list you have a bunch of
names. Each of these names represents a variable that you have defined. We
have the names: Rand and Egwene in the list. And we also have variables that
are called Rand and Egwene.

This list would look like this:

   # Items in list Names(2):
   001: Egwene
   002: Rand

And we have two variables defined:

   # Defined Variables:
   001: {Egwene} {100}
   002: {Rand} {250}

Now lets say we want to see the value of a variable using the list procedures.
If we just use the normal list procedures we are only going to get the text
names from the list. @Var provides a way to take that text name and look it up
as if it were a variable.

   @GetItem(Names,1) would get use the first name in the list: "Egwene"

   @Var(@GetItem(Names,1)) would first get the text "Egwene" from the list
   then the text would be used by the @Var procedure to look up "Egwene" as if
   it were a variable name; which it is. @Var would then return the value of
   the variable; which is 100.
]])
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


MMCompat.add_help('@Version', [[
Format: @Version()

Returns the version of MMCompat.
]])


MMCompat.add_help('@Word', [[
Format: @Word(string,word number)

Word returns a specific word from a string. A handy use for this procedure is
passing in multiple words to an alias -- the alias can then easily separate
the different words.

@Word(This is a test,2)
This would return the word "is".

/alias {test %0} {say @Word($0,2)}
Typing "test This is a test" would pull the second word out of the string
passed to the alias and produce: "say is"
]])
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


MMCompat.add_help('@WordCount', [[
Format: @WordCount(text)

Returns the number of words in the text passed in.
]])
function MMCompat.procWordCount(str)
    if not str or str == "" then
        return 0
    end

    local count = 0

    for word in str:gmatch("%S+") do
        count = count + 1
    end

    return count
end

MMCompat.add_help('@Year', [[
Format: @Year()

Returns the year of the current date.
]])