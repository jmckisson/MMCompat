-- MudMaster Compatibility Script
-- 
-- use %# to indicate an argument that must be provided
-- use $# to indicate the appropriately numbered argument
-- use wait # to wait that many seconds, including decimal seconds, before continuing to the next command

-- Code inspired from user Jor'Mox on the Mudlet forums
-- https://forums.mudlet.org/viewtopic.php?t=16462

MMCompat = MMCompat or {
  isInitialized = false,
  isDebug = false,
  scriptAliases = {},
  maxWhileLoop = 100,
  version = "__VERSION__" or "NotMuddledYet",
  helpAliasId = nil,
  helpEntries = 1,
  save = {
    actions = {},
    aliases = {},
    arrays = {},
    events = {},
    lists = {},
    macros = {},
    variables = {},
  }
}

MMGlobals = MMGlobals or {}

MMCompat.help = {[[
<cyan>MMCompat - MudMaster Compatibility<reset>

  MMCompat aims to provide command-line scriptability using the MudMaster script
  API. MudMaster commands can be entered on the Mudlet command-line and will be
  interpreted by this script and converted to Mudlet commands. Actions, Aliases,
  Events, such as /action, /alias, /event will be created as Mudlet Triggers,
  Aliases and Timers accordingly. Other commands such as /variable will create
  a variable in the global MMGlobal namespace which are used when the $ expansion
  occurs in MudMaster commands.

  ***Important Note***
  MudMaster uses a semicolon ; as a command separator, by default Mudlet uses two
  semicolons ;;. MMCompat will not function properly if you have changed your
  Mudlet command separator to a single semicolon!

<cyan>MudMaster Commands:<reset>

  Commands are prefixed by a forward-slash /.

    <link: action>action</link>  - Create an Action (Mudlet trigger)
    <link: alias>alias</link>   - Create an Alias
    <link: array>array</link>   - Create an array
    <link: assign>assign</link>  - Assign a variable to an array
    <link: event>event</link>   - Create an Event (Mudlet timer)

  All Commands:
    <show_all>

<cyan>MudMaster Procedures:<reset>

  Procedures are special commands prefixed by the @ character and can be used
  in-line with Commands. Example: /chatall @AnsiReset()@ForeBlue()hello!
  will chat 'hello!' to all chat connections with the normal blue color.

]]
}

--[[
local runQueue
function runQueue(fnc,tbl)
    local info = table.remove(tbl,1)
    if info then
        local run = function()
                fnc(info[2])
                runQueue(fnc,tbl)
            end
        if info[1] ~= 0 then
            tempTimer(info[1], run)
        else
            run()
        end
    end
end

local function doQueue(fnc,...)
    local tbl = {}
    local args = arg
    if type(arg[1]) == "table" then args = arg[1] end
    for k,v in ipairs(args) do
        if k % 2 == 1 and type(v) ~= "number" then
            table.insert(args,k,0)
        end
    end
    for k = 1,#args,2 do
        tbl[(k + 1) / 2] = {args[k],args[k+1]}
    end
    runQueue(fnc,tbl)
end

function sendQueue(...)
    doQueue(send,...)
end

function expandQueue(...)
    doQueue(expandAlias,...)
end
]]

function MMCompat.debug(msg)
  if MMCompat.isDebug then
      cecho(string.format("\n<white>[<indian_red>MMCompat<orange>Debug<white>] %s", msg))
  end
end


function MMCompat.echo(msg)
  cecho(string.format("\n<white>[<indian_red>MMCompat<white>] %s", msg))
end


function MMCompat.error(msg)
  cecho(string.format("\n<white>[<indian_red>MMCompat <red>Error<white>] %s", msg))
end


local function add_help(cmd, entry)
  MMCompat.helpEntries = MMCompat.helpEntries + 1
  MMCompat.help[cmd] = entry
  MMCompat.helpCmds = MMCompat.helpCmds or {}
  table.insert(MMCompat.helpCmds, cmd)
end


function MMCompat.add_command(cmd, cmdTbl)
  --cmdTable has help, pattern, func
  local funcTbl = {
    name = cmd,
    pattern = cmdTbl.pattern,
    cmd = cmdTbl.func
  }

  table.insert(MMCompat.functions, funcTbl)

  add_help(cmd, cmdTbl.help)
end


--[[
Help funcion, adapted from generic_mapper
]]
function MMCompat.show_help(cmd)
  if cmd and cmd ~= "" then
      --if cmd:starts("map ") then cmd = cmd:sub(5) end
      cmd = cmd:lower():gsub(" ","_")
      if not MMCompat.help[cmd] then
          MMCompat.echo("No help file on that command.")
      end
  else
      cmd = 1
  end

  for w in MMCompat.help[cmd]:gmatch("[^\n]*\n") do

    -- Special tag to show all commands with links
    if w:find("<show_all>") then
      -- Show all commands from MMCompat.helpCmds
      local sorted_cmds = {}
      for _, help_cmd in pairs(MMCompat.helpCmds) do
          table.insert(sorted_cmds, help_cmd)
      end

      -- Sort the commands alphabetically
      table.sort(sorted_cmds)

      local lineCount = 0
      for _, help_cmd in pairs(sorted_cmds) do
          cecho(" ")
          fg("yellow")
          setUnderline(true)
          echoLink(help_cmd, [[MMCompat.show_help("]] .. help_cmd .. [[")]], "View: " .. help_cmd, true)
          setUnderline(false)
          resetFormat()
          lineCount = lineCount + 1
          if lineCount == 10 then
            echo("\n")
            lineCount = 0
          end
      end
      echo("\n")

    elseif w:find("<related>") then
      -- Search for related commands based on keywords from the current help text
      local current_help_text = MMCompat.help[cmd]:lower()
      for help_cmd, help_text in pairs(MMCompat.help) do
          -- If the current help text contains any part of the other help text, it's considered related
          if help_cmd ~= cmd and current_help_text:find(help_cmd) then
              cecho("\n")
              fg("green")
              setUnderline(true)
              echoLink(help_cmd, [[MMCompat.show_help("]] .. help_cmd .. [[")]], "Related: " .. help_cmd, true)
              setUnderline(false)
              resetFormat()
          end
      end
      echo("\n")

    else

      -- handle <url> and <link> tags
      local url, target = rex.match(w, [[<(url)?link: ([^>]+)>]])
      -- lrexlib returns a non-capture as 'false', so determine which variable the capture went into
      if target == nil then target = url end
      if target then
          local before, linktext, _, link, _, after, ok = rex.match(w,
                        [[(.*)<((url)?link): [^>]+>(.*)<\/(url)?link>(.*)]], 0, 'm')
          -- could not get rex.match to capture the newline - fallback to string.match
          local _, _, after = w:match("(.*)<u?r?l?link: [^>]+>(.*)</u?r?l?link>(.*)")

          cecho(before)
          fg("yellow")
          setUnderline(true)
          if linktext == "urllink" then
              echoLink(link, [[openWebPage("]]..target..[[")]], "Open webpage", true)
          elseif target ~= "1" then
              echoLink(link,[[MMCompat.show_help("]]..target..[[")]],"View: MMCompat help " .. target,true)
          else
              echoLink(link,[[MMCompat.show_help()]],"View: MMCompat help",true)
          end
          setUnderline(false)
          resetFormat()
          if after then cecho(after) end
      else
          cecho(w)
      end
    end
  end
end


-- Function to replace %1, %2, etc., with named regex captures in the patterns
-- of triggers and aliases
function MMCompat.parseCaptures(pattern)
  local result = ""

  -- we need to go thru all of this hooplah because gsub will complain if trying to replace %1 with something
  local i = 0
  while i <= #pattern do
    local c = pattern:sub(i, i)

    if c == "%" then
      local j = i + 1
      local digits = ""

      -- Collect all digits following the %
      while j <= #pattern and pattern:sub(j, j):match("%d") do
        digits = digits .. pattern:sub(j, j)
        j = j + 1
      end

      MMCompat.debug("digits: " .. digits)

      if #digits > 0 then
        -- Create a named capture group using the collected digits
        local capture_name = "capture" .. digits
        result = result .. "(?<" .. capture_name .. ">.*)"
        MMCompat.debug("captureName: " .. capture_name)
        i = j -- Skip over the % and the digits
      else
        -- no digits follow %, just add the % to the result
        result = result .. c
        i = i + 1
      end

      --[[
      -- Check if the next character is a digit
      local next_char = pattern:sub(i + 1, i + 1)
      if next_char:match("%d") then
        -- Create a named capture group using the digit
        local capture_name = "capture" .. next_char
        result = result .. "(?<" .. capture_name .. ">.*)"
        i = i + 2 -- Skip over the % and the digit

      else
        -- If it's not a digit, just add the % to the result
        result = result .. c
        i = i + 1
      end
      --]]
    else
      -- Regular character, just add it to the result
      result = result .. c
      i = i + 1
    end
  end

  return result
end

function MMCompat.findStatement(strText)
  local ptrInc = 1
  local strResult = ""
  local buffer = {}

  -- Trim leading spaces and tabs
  while ptrInc <= #strText and (strText:sub(ptrInc, ptrInc) == ' ' or strText:sub(ptrInc, ptrInc) == '\t') do
      ptrInc = ptrInc + 1
  end

  if ptrInc > #strText then
      return true, "" -- Nothing to process
  end

  -- Define characters used for block start, end, escape, and procedure
  local chStartChar = '{'
  local chEndChar = '}'
  local chEscape = '\\'
  local procChar = '@'

  -- Determine if block delimiters are spaces
  local nBlockCount = 0
  if strText:sub(ptrInc, ptrInc) ~= chStartChar then
      chEndChar = ' '
      chStartChar = ' '
      nBlockCount = 1 -- Start with a block already active
  end

  local nProcCount = 0
  local nPotentialProcCount = 0
  local ch1 = ""

  while ptrInc <= #strText do
      local ch = strText:sub(ptrInc, ptrInc)
      ch1 = strText:sub(ptrInc + 1, ptrInc + 1)

      -- Handle escape sequences for procedure characters
      if ch == chEscape and ch1 == procChar then
          table.insert(buffer, chEscape)
          table.insert(buffer, procChar)
          ptrInc = ptrInc + 2
      elseif ch == procChar then
          -- Handle procedures
          nPotentialProcCount = nPotentialProcCount + 1
          table.insert(buffer, ch)
          ptrInc = ptrInc + 1
      elseif ch == '(' and nPotentialProcCount > 0 then
          -- Handle procedure parentheses
          nProcCount = nProcCount + 1
          nPotentialProcCount = nPotentialProcCount - 1
          table.insert(buffer, ch)
          ptrInc = ptrInc + 1
      elseif ch == chEscape and ch1 == ')' then
          -- Escape sequences for closing parentheses
          table.insert(buffer, chEscape)
          table.insert(buffer, ')')
          ptrInc = ptrInc + 2
      elseif ch == ')' and nProcCount > 0 then
          -- Decrement procedure count for closing parentheses
          nProcCount = nProcCount - 1
          table.insert(buffer, ch)
          ptrInc = ptrInc + 1
      elseif ch == chEndChar and nProcCount == 0 then
          -- Handle block ending character
          nBlockCount = nBlockCount - 1
          if nBlockCount == 0 then
              ptrInc = ptrInc + 1 -- Move past the closing delimiter
              break
          else
              table.insert(buffer, ch)
              ptrInc = ptrInc + 1
          end
      elseif ch == chStartChar and nBlockCount == 0 then
          -- Handle block starting character
          nBlockCount = nBlockCount + 1
          ptrInc = ptrInc + 1
      elseif ch == chStartChar and nProcCount == 0 then
          -- Nested blocks
          nBlockCount = nBlockCount + 1
          table.insert(buffer, ch)
          ptrInc = ptrInc + 1
      else
          -- Add the character to the buffer
          table.insert(buffer, ch)
          ptrInc = ptrInc + 1
      end
  end

  -- Handle mismatched parentheses
  if nProcCount > 0 then
      MMCompat.debug(string.format("Mismatched parens processing text:\nThis Line-->[%s]\n", strText))
  end

  -- Process the remaining text
  local remainingText = strText:sub(ptrInc)
  strResult = table.concat(buffer)

  return true, strResult, remainingText
end


--[[
  Ported code from MudMaster2k source
]]
function MMCompat.findStatement2(strText)
  local strResult = ""
  local ptrInc = 1

  if MMCompat.isDebug then
    MMCompat.echo("findStatement: strText =")
    display(strText)
    echo("\n")
  end

  -- Trim leading spaces and tabs
  while ptrInc <= #strText and (strText:sub(ptrInc, ptrInc) == ' ' or strText:sub(ptrInc, ptrInc) == '\t') do
      ptrInc = ptrInc + 1
  end

  if ptrInc > #strText then
      return true, ""
  end

  local chEndChar = '}'
  local chStartChar = '{'
  local chEscape = '\\'

  local nBlockCount = 0
  if strText:sub(ptrInc, ptrInc) ~= chStartChar then
      chEndChar = ' '
      chStartChar = ' '
      nBlockCount = 1
  end

  local nProcCount = 0
  local nPotentialProcCount = 0
  local buffer = {}

  local ch1 = ""
  local procChar = '@'

  while ptrInc <= #strText do
      local ch = strText:sub(ptrInc, ptrInc)
      ch1 = strText:sub(ptrInc + 1, ptrInc + 1)

      if ch == chEscape and ch1 == procChar then
          table.insert(buffer, '\\')
          table.insert(buffer, procChar)
          ptrInc = ptrInc + 2

      elseif ch == procChar then
          -- Need to watch for procedures.  Each time we find a procedure
          -- we need to look for a matched set of parens.
          nPotentialProcCount = nPotentialProcCount + 1
          table.insert(buffer, ch)
          ptrInc = ptrInc + 1

      elseif ch == '(' and nPotentialProcCount > 0 then
        -- if we've seen an @ and now a ( it is a procedure
          nProcCount = nProcCount + 1
          nPotentialProcCount = nPotentialProcCount - 1
          table.insert(buffer, ch)
          ptrInc = ptrInc + 1

      elseif ch == chEscape and ch1 == ')' then
        -- If the user wants to print a closing paren while inside
		    -- a procedure definition, they need to use the escape char.
          table.insert(buffer, '\\')
          table.insert(buffer, ')')
          ptrInc = ptrInc + 2
      else
          if ch == ')' and nProcCount > 0 then
              nProcCount = nProcCount - 1
          end

          if ch == chEndChar and nProcCount == 0 then
              nBlockCount = nBlockCount - 1
              if nBlockCount == 0 then
                  ptrInc = ptrInc + 1
                  break
              end
          end

          if ch == chStartChar and nBlockCount == 0 then
              nBlockCount = nBlockCount + 1
              ptrInc = ptrInc + 1
          elseif ch == chStartChar and nProcCount == 0 then
              nBlockCount = nBlockCount + 1
              ptrInc = ptrInc + 1
          else
              table.insert(buffer, ch)
              ptrInc = ptrInc + 1
          end
      end
  end

  if nProcCount > 0 then
      local strMessage = string.format("Mismatched parens processing text:\nThis Line-->[%s]\n", strText)
      MMCompat.debug(strMessage)
  end

  if ch1 ~= "" then
      strText = strText:sub(ptrInc)
  else
      strText = ""
  end

  strResult = table.concat(buffer)

  MMCompat.debug("findStatement: output:: ")
  display(buffer)
  MMCompat.debug("strResult = '"..strResult.."'")
  MMCompat.debug("strText = '"..strText.."'")

  return true, strResult, strText
end


-- Function to replace $variables in the string with a reference
-- to MMGlobals[variableName]
function MMCompat.referenceVariables(str, globals_table)

  local anyMatch = false

  -- Find all $variables and replace them in one pass
  for var_name in string.gmatch(str, "%$[%w_]+") do
    local key = var_name:sub(2)  -- Remove the $ symbol
    local valueStr = globals_table[key] or var_name  -- Lookup the value in globals_table or keep the original

    str = string.gsub(str, var_name, valueStr)

    anyMatch = true

    if MMCompat.isDebug then
      echo("var_name: " .. var_name .. "\n")
      echo("key: " .. key .. "\n")
      echo("replaced: " .. str .. "\n")
    end
  end

  local processedStr = MMCompat.replaceProcedureCalls(str)

  return processedStr, anyMatch
end


-- Function to replace $variables in the string with the actual value
-- of MMGlobals[variableName]
function MMCompat.replaceVariables(str, encapsulate)

  local anyMatch = false

  -- Find all $variables and replace them in one pass
  for var_name in string.gmatch(str, "%$[%w_]+") do
    local key = var_name:sub(2)  -- Remove the $ symbol
    local keyNum = tonumber(key)
    if keyNum then
      key = "capture"..key
    end

    --local value = globals_table[key] or var_name  -- Lookup the value in globals_table or keep the original
    local valueStr = ""
    if encapsulate then
      valueStr = "\"..MMGlobals['"..key.."']..\""
    else
      valueStr = "MMGlobals['"..key.."']"
    end

    str = string.gsub(str, var_name, valueStr)

    anyMatch = true

    if MMCompat.isDebug then
      echo("var_name: " .. var_name .. "\n")
      echo("key: " .. key .. "\n")
      echo("replaced: " .. str .. "\n")
    end

    MMGlobals[key] = MMGlobals[key] or ""
  end

  -- Process any procedure calls in the statement
  local processedStr = MMCompat.replaceProcedureCalls(str)

  return processedStr, anyMatch
end

-- Template code to assign the matches global to entries in MMGlobals
--[[
function MMCompat.templateAssignGlobalMatches()
  for n=2, #matches do
    local var = tostring(matches[n-1])
    if var then
      local captureNum = var:match("%d+")
      if captureNum then
        MMGlobals[captureNum] = matches[n]
      end
    end
    --MMGlobals[var] = matches[n]
  end
end
--]]

function MMCompat.templateAssignGlobalMatches()
  if MMCompat.isDebug then
    display(matches)
    echo("\n")
  end

  for k, v in pairs(matches) do
    MMCompat.debug(string.format("assigning key: %s  value: %s", k, v))
    if not tonumber(k) then
      -- this is a named capture
      MMGlobals[k] = v
    end
  end
end

function MMCompat.parseCommands(cmds, includeMatchExpansion, reference)
  -- Split commands by semicolon
  cmds = string.split(cmds, "%s*;%s*")

  if MMCompat.isDebug then
      display(cmds)
  end

  local expandedStr = ""
  local anyMatchReplacements = false

  -- Loop over all commands
  for k, v in ipairs(cmds) do
      MMCompat.debug(string.format('Processing command %s', v))

      local cmd = ""

      -- Check if the command is a 'wait' command
      --if string.match(v, "wait [%d%.]+") then
      --    cmd = string.match(v, "^wait ([%d%.]+)$")
      --else
          cmd = v
      --end

      -- Replace variables in the command
      local expandedCmd = ""
      if not reference then
          expandedCmd, anyMatchReplacements = MMCompat.replaceVariables(cmd, true)
      else
          expandedCmd, anyMatchReplacements = MMCompat.referenceVariables(cmd, MMGlobals)
      end

      -- Call expandAlias for each expanded command
      expandedStr = expandedStr .. "expandAlias(\""..expandedCmd.."\")\n"
  end

  -- Add code that puts all matches into MMGlobals, if necessary
  local matchStr = ""
  if anyMatchReplacements and includeMatchExpansion then
      matchStr = [[MMCompat.templateAssignGlobalMatches()]]
      matchStr = matchStr .. "\n"
  end

  return matchStr .. expandedStr
end

function MMCompat.parseCommands2(cmds, includeMatchExpansion, reference)
  -- split commands by semicolon
  cmds = string.split(cmds,"%s*;%s*")

  if MMCompat.isDebug then
    display(cmds)
  end

  local str = "expandQueue("
  local start, match, stop, tmp
	local comma = ""

  -- loop over all commands
  for k,v in ipairs(cmds) do

    MMCompat.debug(string.format('Processing command %s', v))

    if string.match(v,"wait [%d%.]+") then
      str = str .. comma .. string.match(v,"^wait ([%d%.]+)$")
    else
      str = str .. comma .. [["]] .. v .. [["]]
    end

		comma = ","
  end

  str = str .. ")"

  local expandedStr= ""
  local anyMatchReplacements = false
  if not reference then
    expandedStr, anyMatchReplacements = MMCompat.replaceVariables(str, true)
  else
    expandedStr, anyMatchReplacements = MMCompat.referenceVariables(str, MMGlobals)
  end

  if MMCompat.isDebug then
    echo("expandedStr: " .. expandedStr .. "\n")
  end

  -- Add code that puts all matches into MMGlobals
  -- Only if the resulting code uses the matches table
  local matchStr = ""
  if anyMatchReplacements and includeMatchExpansion then
    matchStr = [[MMCompat.templateAssignGlobalMatches()]]
    matchStr = matchStr .. "\n"
  end

  return matchStr .. expandedStr
end

local function findProcedure(name)
  for _, proc in ipairs(MMCompat.procedures) do
      if proc.name == name then
          return proc.cmd
      end
  end
  return nil
end

local function parseArgument(arg)
  -- Try to convert numbers
  local number = tonumber(arg)
  if number then
      return number
  end
  -- If the argument is quoted, treat it as a string
  local str = arg:match("^%s*['\"](.-)['\"]%s*$")
  if str then
      return str
  end

  MMCompat.debug("parsedArgument: " .. arg)
  -- Return the argument as-is if no conversion was possible
  return arg
end

-- Function to evaluate and replace procedure calls
function MMCompat.replaceProcedureCalls(text)
  -- Pattern to find calls like @ProcedureName(arg1, arg2, ...)
  local pattern = "@(%w+)%((.-)%)"

  -- Function to process each match
  local function processProcCall(procedure_name, arguments)
      -- Find the function by procedure name
      local procedure = findProcedure(procedure_name)
      if procedure then
          -- Split arguments by comma and trim spaces
          local args = {}
          for arg in arguments:gmatch("[^,]+") do
            local strFunc = parseArgument(arg)
            MMCompat.debug("processProcCall strFunc: " .. strFunc)
            table.insert(args, strFunc)
          end
          -- Call the procedure with the parsed arguments
          local result = procedure(unpack(args))

          return tostring(result)
      else
          -- If the procedure is not found, return the original text
          return "@" .. procedure_name .. "(" .. arguments .. ")"
      end
  end

  -- Replace all matches in the input text
  return text:gsub(pattern, processProcCall)
end

function MMCompat.parseCondition(cmds)

  local expandedStr, _ = MMCompat.replaceVariables(cmds, false)

  return expandedStr
end


function MMCompat.createParentGroup(group, itemType, itemParent)

  if MMCompat.isDebug then
    local debugTbl = {
      group = group,
      itemType = itemType,
      itemParent = itemParent
    }

    echo("createParentGroup\n")
    display(debugTbl)
  end

  -- Create encompassing group
  if group and group ~= "" then

    -- group is not empty
    if exists(group, itemType) == 0 then
      -- group does not exist, create it under the parent itemParent
      echo("Creating group " .. itemType .. "/" .. group.."\n")
      permGroup(group, itemType, itemParent)
      return group
    else
      -- Group already exists, return the itemParent without creating new group
      echo("Group " .. itemType .. "/" .. group .." exists\n")
      return itemParent
    end

  end

  -- group was empty, just use itemParent
  return itemParent
end


function MMCompat.executeString(cmds)
  -- Assemble the command as a function
  local functionString = "return function() " .. cmds .. " end"

  --echo("functionString: " .. functionString .. "\n")

  local loadedFunction = loadstring(functionString)

  if not loadedFunction then
    error("Failed to load function from string")
  end

  -- Get function from the loaded chunk
  local myFunction = loadedFunction()

  local result = myFunction()

  return result
end

function MMCompat.findArray(name, row, col)
  local found = false
  for k, v in pairs(MMCompat.save.arrays) do
      if v.name == name then
          found = true
          -- check bounds
          if row > v.bounds.rows then
              MMCompat.error(string.format("Array '%s' row index out of bounds, given %d, bounds %d",
                  v.name, row, v.bounds.row))
              return
          end
          if v.bounds.cols and col and col > v.bounds.cols then
              MMCompat.error(string.format("Array '%s' col index out of bounds, given %d, bounds %d",
                  v.name, col, v.bounds.col))
              return
          end
          break
      end
  end

  return found
end

function MMCompat.audit()
  for k, v in pairs(MMCompat.save.actions) do
    if exists(v.pattern, "trigger") == 0 then
      MMCompat.warning("Action " ..v.pattern.." does not exist\n")
    end
  end

  for k, v in pairs(MMCompat.save.aliases) do
    if exists(v.pattern, "alias") == 0 then
      MMCompat.warning("Alias " ..v.pattern.." does not exist\n")
    end
  end

  for k, v in pairs(MMCompat.save.events) do
    if exists(v.name, "timer") == 0 then
      MMCompat.warning("Event " ..v.name.." does not exist\n")
    end
  end

  for k, v in pairs(MMCompat.save.arrays) do
    if not MMGlobals[v] then
      MMCompat.warning("Array " ..v.." does not exist\n")
      MMGlobals[v] = {
        bounds = v.bounds,
        name = v.name,
        value = {}
      }
    end
  end

  for k, v in pairs(MMCompat.save.lists) do
    if not MMGlobals[v] then
      MMCompat.warning("List " ..v.." does not exist\n")
      MMGlobals[v] = {}
    end
  end

  for k, v in pairs(MMCompat.save.variables) do
    if not MMGlobals[v] then
      MMCompat.warning("Variable " ..v.." does not exist\n")
      MMGlobals[v] = ""
    end
  end
end


function MMCompat.config()

    for _,v in ipairs(MMCompat.scriptAliases) do
        killAlias(v)
    end

    MMCompat.scriptAliases = {}
    MMCompat.functions = {}
    

    --      {name="event",        pattern=[[^/event {(.*?)}\s*{(\d+?)}\s*{(.*?)}\s*(?:{(.*)})?$]],      cmd=[[MMCompat.makeEvent(matches[2], matches[3], matches[4], matches[5])]]},

    --MMCompat.audit()


    MMCompat.procedures = {
      {name="A",              cmd=MMCompat.procGetArray},
      {name="Abs",            cmd=function(val) return math.abs(val) end},
      {name="AnsiBold",       cmd=function() return "\27[1m" end},
      {name="AnsiReset",      cmd=function() return "\27[0m" end},
      {name="AnsiReverse",    cmd=function() return "\27[7m" end},
      {name="Arr",            cmd=MMCompat.procGetArray},
      {name="Asc",            cmd=MMCompat.procAsc},
      {name="BackBlack",      cmd=function(val) return "\27[40m" end},
      {name="BackBlue",       cmd=function(val) return "\27[44m" end},
      {name="BackColor",      cmd=MMCompat.procBackColor},
      {name="BackCyan",       cmd=function() return "\27[46m" end},
      {name="BackGreen",      cmd=function() return "\27[42m" end},
      {name="BackMagenta",    cmd=function() return "\27[45m" end},
      {name="BackRed",        cmd=function() return "\27[41m" end},
      {name="BackYellow",     cmd=function() return "\27[43m" end},
      {name="Backward",       cmd=function(str) return str:reverse() end},
      {name="BackWhite",      cmd=function() return "\27[7m" end},
      {name="Chr",            cmd=function(val) return string.char(val) end},
      {name="Commma",         cmd=MMCompat.procComma},
      {name="CommandToList",  cmd=MMCompat.procCmdToList},
      {name="ConCat",         cmd=function(a, b) return a..b end},
      {name="Connected",      cmd=MMCompat.procConnected},
      {name="Day",            cmd=function() return os.date("%A") end},
      {name="DeComma",        cmd=MMCompat.procDeComma},
      {name="EventTime",      cmd=MMCompat.procEventTime},
      {name="Exists",         cmd=MMCompat.procExists},
      {name="FileExists",     cmd=MMCompat.procFileExists},
      {name="ForeBlack",      cmd=function() return "\27[30m" end},
      {name="ForeBlue",       cmd=function() return "\27[34m" end},
      {name="ForeColor",      cmd=MMCompat.procForeColor},
      {name="ForeCyan",       cmd=function() return "\27[36m" end},
      {name="ForeGreen",      cmd=function() return "\27[32m" end},
      {name="ForeMagenta",    cmd=function() return "\27[35m" end},
      {name="ForeRed",        cmd=function() return "\27[31m" end},
      {name="ForeYellow",     cmd=function() return "\27[33m" end},
      {name="ForeWhite",      cmd=function() return "\27[37m" end},
      {name="GetArray",       cmd=MMCompat.procGetArray},
      {name="GetCount",       cmd=MMCompat.procGetCount},
      {name="GetItem",        cmd=MMCompat.procGetItem},
      {name="Hour",           cmd=function() return os.date("%H") end},
      {name="If",             cmd=MMCompat.procIf},
      {name="InList",         cmd=MMCompat.procInList},
      {name="IsNumber",       cmd=function(val) return tonumber(val ~= nil) end},
      {name="IsEmpty",        cmd=function(list) return table.is_empty(MMGlobals[list]) end},
      {name="IP",             cmd=function() return "127.0.0.1" end},
      {name="Left",           cmd=function(val, n) return string.sub(val, 1, n) end},
      {name="Len",            cmd=function(str) return string.len(str) end},
      {name="Lower",          cmd=function(val) return string.lower(val) end},
      {name="LTrim",          cmd=function(val) return val:match("^%s*(.-)$") end},
      {name="Math",           cmd=MMCompat.procMath},
      {name="Mid",            cmd=function(str, start, n) return string.sub(str, start, start + n - 1) end},
      {name="Minute",         cmd=function() return os.date("%M") end},
      {name="Month",          cmd=function() return os.date("%B") end},
      {name="NumActions",     cmd=function() return #MMCompat.save.actions end},
      {name="NumAliases",     cmd=function() return #MMCompat.save.aliases end},
      {name="NumBarItems",    cmd=MMCompat.procNumBarItems},
      {name="NumEvents",      cmd=function() return #MMCompat.save.events end},
      {name="NumGags",        cmd=MMCompat.procNumGags},
      {name="NumHighlights",  cmd=MMCompat.procNumHighLights},
      {name="NumLists",       cmd=function() return #MMCompat.save.lists end},
      {name="NumMacros",      cmd=function() return getProfileStats().keys.active end},
      {name="NumTabList",     cmd=MMCompat.procNumTabList},
      {name="NumVariables",   cmd=function() return #MMCompat.save.variables end},
      {name="PadLeft",        cmd=function(str, char, n) return string.rep(char, n) .. str end},
      {name="PadRight",       cmd=function(str, char, n) return str .. string.rep(char, n) end},
      {name="PreTrans",       cmd=function(val) return MMCompat.referenceVariables(val) end},
      {name="ProcedureCount", cmd=function() return #MMCompat.procedures end},
      {name="Random",         cmd=function(val) return math.random(1, val) end},
      {name="Replace",        cmd=MMCompat.procReplace},
      {name="Right",          cmd=function(val, n) return string.sub(val, -n) end},
      {name="RTrim",          cmd=function(val) return val:match("^(.-)%s*$") end},
      {name="Second",         cmd=function() return os.date("%S") end},
      {name="SessionName",    cmd=function() return getProfileName() end},
      {name="SessionPath",    cmd=MMCompat.procGetSessionPath},
      {name="StripAnsi",      cmd=MMCompat.procStripAnsi},
      {name="StrStr",         cmd=function(str, search) return string.find(str, search) end},
      {name="StrStrRev",      cmd=MMCompat.procStrStrRev},
      {name="Substr",         cmd=function(val, n, m) return string.sub(val, n-1, m-1) end},
      {name="Time",           cmd=function() return string.format("%d", os.time()) end},
      {name="TextColor",      cmd=MMCompat.procTextColor},
      {name="Upper",          cmd=function(val) return string.upper(val) end},
      {name="Var",            cmd=MMCompat.procVar},
      {name="Version",        cmd=function() return "MMCompat " .. MMCompat.version end},
      {name="Word",           cmd=MMCompat.procWord},
      {name="WordColor",      cmd=MMCompat.procWordColor},
      {name="WordCount",      cmd=MMCompat.procWordCount},
      {name="Year",           cmd=function() return os.date("%Y") end}

    }

    tempTimer(.25, [[MMCompat.display_info()]])

end

function MMCompat.display_info()
  -- yea this probably doesnt belong here, move later
  for _,v in pairs(MMCompat.functions) do
    local aliasId = tempAlias(v.pattern, v.cmd)
  --  cecho(string.format("\n<white>[<indian_red>MMCompat<white>] Loaded <LawnGreen>%s <white>command, id: <green>%d", v.name, aliasId))
    table.insert(MMCompat.scriptAliases, aliasId)
  end

  MMCompat.echo(string.format("MudMaster Compatibility v <yellow>%s <white>loaded...", MMCompat.version))
  MMCompat.echo(string.format("    <green>%d <white>commands, <green>%d <white>procedures, <green>%d <white>help entries",
    #MMCompat.functions, #MMCompat.procedures, MMCompat.helpEntries))
  MMCompat.echo("Type /help for the MudMaster help system")

  if getCommandSeparator() == ';' then
    MMCompat.warning("You have defined your Mudlet command separator as a single semicolon")
    MMCompat.warning("This will interfere with the functionality of MMCompat!")
  end
end


function MMCompat.saveData()
  local charName = string.lower(getProfileName())
  
  local saveTable = table.deepcopy(MMCompat.save)
  
  table.save(getMudletHomeDir().."/mmcompat_"..charName..".lua", saveTable)
end


function MMCompat.loadData()
  local charName = string.lower(getProfileName())
  
  local loadTable = {}
  local tablePath = getMudletHomeDir().."/mmcompat_"..charName..".lua"
  if io.exists(tablePath) then
    table.load(tablePath, loadTable)
  end
  
  MMCompat.save = table.deepcopy(loadTable)

  MMCompat.save.actions = MMCompat.save.actions or {}
  MMCompat.save.aliases = MMCompat.save.actions or {}
  MMCompat.save.arrays = MMCompat.save.arrays or {}
  MMCompat.save.events = MMCompat.save.actions or {}
  MMCompat.save.lists = MMCompat.save.lists or {}
  MMCompat.save.macros = MMCompat.save.macros or {}
  MMCompat.save.variabes = MMCompat.save.actions or {}
  
  MMCompat.cecho("Loaded MudMaster script data for <yellow>" .. charName)
end


if not MMCompat.isInitialized then
  math.randomseed(os.time())
  MMCompat.config()
end

if MMCompat.helpAliasId then
  killAlias(MMCompat.helpAliasId)
end

MMCompat.helpAliasId = tempAlias([[^/help(?: (.*))?]], [[MMCompat.show_help(matches[2])]])

if exists("MMActions", "trigger") == 0 then
  permGroup("MMActions", "trigger")
end

if exists("MMAliases", "alias") == 0 then
  permGroup("MMAliases", "alias")
end

if exists("MMEvents", "timer") == 0 then
  permGroup("MMEvents", "timer")
end

MMCompat.isInitialized = true