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
  scriptAliases = {}
}

MMGlobals = MMGlobals or {}

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

function MMCompat.echo(msg)
  cecho(string.format("\n<white>[<indian_red>MMCompat<white>] %s", msg))
end


-- Function to replace %1, %2, etc., with named regex captures in the patterns
-- of triggers and aliases
function MMCompat.parseCaptures(pattern)
  local result = ""

  -- we need to go thru all of this hooplah because gsub will complain if trying to replace %1 with something
  local i = 1
  while i <= #pattern do
    local c = pattern:sub(i, i)
    if c == "%" then
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
    else
      -- Regular character, just add it to the result
      result = result .. c
      i = i + 1
    end
  end

  return result
end


-- Function to replace $variables in the string
function MMCompat.replaceVariables(str, encapsulate)

  local anyMatch = false

  -- Find all $variables and replace them in one pass
  for var_name in string.gmatch(str, "%$[%w_]+") do
    local key = var_name:sub(2)  -- Remove the $ symbol
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
  end

  return str, anyMatch
end

-- Template code to assign the matches global to entries in MMGlobals
function MMCompat.templateAssignGlobalMatches()
  for n=2, #matches do
    local var = tostring(n-1)
    MMGlobals[var] = matches[n]
  end
end


function MMCompat.parseCommands(cmds, includeMatchExpansion)
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

    if MMCompat.isDebug then
      echo("Processing command '"..v.."'\n")
    end

    if string.match(v,"wait [%d%.]+") then
      str = str .. comma .. string.match(v,"^wait ([%d%.]+)$")

    --elseif string.match(v,"%%%d+") then
      -- 
    --  tmp = ""

		--	for start, match, stop in string.gmatch(v,"(.-)%%(%d+)([^%%]*)") do
    --    tmp = tmp .. string.format([[%s" .. matches[%s] .. "%s]], start, match + 1, stop)
    --    echo(tmp .. "\n")
    --  end

    --  str = str .. comma .. [["]] .. tmp .. [["]]
    else
      str = str .. comma .. [["]] .. v .. [["]]
    end

		comma = ","
  end

  str = str .. ")"

  local expandedStr, anyMatchReplacements = MMCompat.replaceVariables(str, true)

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

function MMCompat.parseCondition(cmds)

  local expandedStr, _ = MMCompat.replaceVariables(cmds, false)

  return expandedStr
end


local function createParentGroup(group, itemType, itemParent)

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


function MMCompat.makeAction(m)

  local ptrn = (m[2] ~= "") and m[2] or m[3]
  local cmds = m[4]
  local group = m[5] or nil

  local pattern = MMCompat.parseCaptures(ptrn)
  local commands = MMCompat.parseCommands(cmds, true)

  if MMCompat.isDebug then
    local tbl = {
      tGroup = group,
      tPattern = ptrn,
      tParsedPattern = pattern,
      tCmds = cmds,
      tItemType = "trigger",
      tCommands = commands
    }

    display(tbl)
  end

  if exists(ptrn, "trigger") ~= 0 then
    MMCompat.echo("Action with the name '<green>" .. ptrn .. "<white>' already exists")
    return
  end

  local treeGroup = createParentGroup(group, "trigger", "MMActions")

  if MMCompat.isDebug then
    echo("Creating trigger '" .. ptrn .. "'\n")

    echo("commands:\n")
    display(commands)
  end

  permRegexTrigger(ptrn, treeGroup, {pattern}, commands)
end


function MMCompat.makeAlias(m)

  if MMCompat.isDebug then
    echo("\nin makeAlias(), matches:\n")
    display(m)
  end

  local ptrn = (m[2] ~= "") and m[2] or m[3]
  local cmds = m[4]
  local group = m[5] or nil

  local pattern = "^/"..MMCompat.parseCaptures(ptrn)
  local commands = MMCompat.parseCommands(cmds, true)

  if MMCompat.isDebug then
    local tbl = {
      tGroup = group,
      tPattern = ptrn,
      tParsedPattern = pattern,
      tCmds = cmds,
      tItemType = "alias"
    }

    display(tbl)
  end

  if exists(ptrn, "alias") ~= 0 then
    MMCompat.echo("Alias with the name '<green>" .. ptrn .. "<white>' already exists")
    return
  end

  -- Create group 'group' under group 'parentGroup', if group exists
  local treeGroup = createParentGroup(group, "alias", "MMAliases")

  permAlias(ptrn, treeGroup, pattern, commands)
end

-- name, frequency, commands, group
function MMCompat.makeEvent(name, freq, cmds, group)
  local commands = MMCompat.parseCommands(cmds, false)

  local itemType = "timer"
  local itemParent = "MMEvents"

  if exists(name, itemType) ~= 0 then
    echo("Event with the name '" .. name .. "' already exists")
    return
  end

  createParentGroup(group, itemType, itemParent)

  permTimer(name, group, freq, commands)
end

-- name, value, group
function MMCompat.makeVariable(m)

  local name = (m[2] ~= "") and m[2] or m[3]
  local value = (m[4] ~= "") and m[4] or m[5]
  local group = (m[6] ~= "") and m[6] or ""

  if MMCompat.isDebug then
    display(m)
    echo(string.format("\nname: %s, value: %s, group: %s\n", name, value, group))
  end

  MMGlobals[name] = value
end


--[[
Format: /listadd {list name} {group name}

Creates a new user defined list.

   * {list name} Name of the list you want to create.
   * {group name} Optional, see the user guide for help on groups.
]]
function MMCompat.listAdd(name, group)
  MMGlobals[name] = MMGlobals[name] or {}
end


--[[
Format: /listcopy {old list} {new list} {a or d}

Copies an entire list into a new list. If you don't provide NewList it uses the
original name with Copy tacked on. If the old list doesn't exist nothing
happens.

   * {old list} Name of the list you want to copy from.
   * {new list} Name of the list to copy to.
   * {a or d} A will sort the list in ascending order, D will sort the list in
     descending order.

Examples:

/listcopy {KhraitShips}
This will duplicate the list called KhraitShips into a list called KhraitShipsCopy.

/listcopy {KhraitShips} {OldKhraitShips} {a}
This will duplicate the list called KhraitShips into a list called
OldKhraitShips and sort the new list in ascending order.
]]
function MMCompat.listCopy(from, to)
  MMGlobals[from] = MMGlobals[from] or {}

  local toName = to and to or from.."Copy"

  MMGlobals[toName] = table.deepcopy(from)
end


--[[
Format: /listdelete {list name}
Format: /listdelete {list number}

Deletes a user defined list and any items in the list.

   * {list name} The name of the list you want to delete.
   * {list number} The number of the list you want to delete.
]]
function MMCompat.listDelete(name)
  table.remove(MMGlobals[name])
end

local is_int = function(n)
  return (type(n) == "number") and (math.floor(n) == n)
end

--[[
Format: /itemadd {list name} {item text}
Format: /itemadd {list number} {item text}

Adds a text string to a user defined list. Lists are sorted by order input.

   * {list name} The name of the list to add the item to.
   * {list number} The number of the list to add the item to.
   * {item text} The text to add to the list.
]]
function MMCompat.itemAdd(m)
  local name = m[2]
  local val = (m[3] ~= "") and m[3] or m[4]
  MMGlobals[name] = MMGlobals[name] or {}

  table.insert(MMGlobals[name], val)
end


--[[
Format: /itemdelete {list name} {item text}
Format: /itemdelete {list name} {item number}
Format: /itemdelete {list number} {item text}
Format: /itemdelete {list number} {item number}

Deletes an item from a user defined list.

   * {list name} The name of the list to delete the item from.
   * {list number} The number of the list to delete the item from.
   * {item text} The text of the item to delete.
   * {item number} The number of the item to delete.
]]
function MMCompat.itemDelete(name, textOrId)
  MMGlobals[name] = MMGlobals[name] or {}

  if is_int(textOrId) then
    table.remove(MMGlobals[name], textOrId)
  else
    MMGlobals[name] = nil
  end
end


--[[
Format: /if {conditional statement} {then} {else}

If commands need to be activated in some fashion in order to be evaluated. Most
commonly you would place an if command inside an action. However, they could
also be place inside an alias or macro. The if command has been modeled after
an if statement in C.

   * {conditional statement} This is a statement that evaluates to either true
     or false. Any statement evaluating to a 0 is considered false, while any
     other result would be considered true.
   * {then} The commands you place here will be executed if the condition is
     evaluated to true.
   * {else} The commands you place here will be executed if the condition is
     evaluated to false. This paramater is optional.

Operators recognized by if:

   Operator   Description               Operator   Description
   --------   ---------------------     --------   ------------------------
   &&         And                       ||         Or
   ==         Equal To                  =          Equal To
   !=         Not Equal To              >          Greater Than
   <          Less Than                 >=         Greater Than or Equal To
   <=         Less Than or Equal To     ()         Precedence
   !          Negation

Operators are evaluated in this order: (), &&, ||, =, ==, !=, >, <, >=, <=.

Conditional statements or parts of conditional statements can be negated with !
as long as the portion of the statement being negated is surrounded by parentheses.
To use !, it would be something like
/if {$0 > 5} {/showme {$0 is smaller}} {/showme {$0 is larger}}

/action {^You are hungry.} {/if {$AutoEat = 1} {take food bag;eat food}}
The above would allow you to turn eating on and off. You need to define a
variable called AutoEat and give it a value of 1 when you want eating to be
automatic, and any other number when you want to turn it off.

/action {%0 enters the room.} {/if {$MeanMode = 1 && "$0" = "Atlas" || "$0" = "Breedan"} {spit $0}}
Assuming the mud sent the text "<character name> enters the room." each time
somebody entered the room. Each time somebody enters the room the client would
check to see if MeanMode is 1, and that the name of the person who entered is
either Atlas or Breedan, and if it is, would spit on them.

NOTE:  Make sure you put double quotes around string variables within if
       conditions.
]]
function MMCompat.doIf(condition, thenCode, elseCode)

  if MMCompat.isDebug then
    local dbgTbl = {
      condition = condition,
      thenCode = thenCode,
      elseCode = elseCode
    }

    echo("doIf\n")
    display(dbgTbl)
  end

  local parsedCondition = "return " .. MMCompat.replaceVariables(condition, false)
  local thenCommands = MMCompat.parseCommands(thenCode, false)
  local elseCommands = MMCompat.parseCommands(elseCode, false)

  if MMCompat.isDebug then
    local dbgTbl = {
      parsedCondition = parsedCondition,
      thenCmds = thenCommands,
      elseCmds = elseCommands
    }

    echo("IF debug:\n")
    display(dbgTbl)

    echo(string.format("IF {%s} {%s} {%s}\n", parsedCondition, thenCommands, elseCommands))
  end

  local result = MMCompat.executeString(parsedCondition)

  if result then
    -- execute then condition
    MMCompat.executeString(thenCommands)
  else
    -- execute else condition
    MMCompat.executeString(elseCommands)
  end

end


--[[
Format: /loop {start,end,variable name} {commands}

Loop increments or decrements a number from start to end. Each time the number
is incremented or decremented the commands are executed. The loop number is
placed in the system variable $LoopCount.

   * {start,end,variable name} The start and ending numbers for the loop. If
     start is bigger than end, the loop will count backwards. Variable name will specify
     which variable to store the Loop number in. This can be left blank and MudMaster will
     default variable name to LoopCount.
   * {commands} The commands to execute for each count of the loop.

/loop {1,3,Loop} {look $Loop.man}
This would send the text "look 1.man" "look 2.man" and "look 3.man" to the mud.
Loop number was stored in variable "$Loop".

/loop {3,1} {look $LoopCount.man}
This does exactly the opposite. The number is decremented rather than
incremented and would send the text: "look 3.man" "look 2.man" "look 1.man".
Since there was no variable name specified to store the Loop number it is
stored in "$LoopCount".
]]
function MMCompat.doLoop(loopBounds, loopVar, cmds)

end

--[[
Format: /while {condition} {commands}

While executes the command as long as the condition is true.

   * {condition} A condition that evaluates to true or false. See help on if
     for information on the condition.
   * {commands} The commands will be executed until the condition is false.

Caution is advised when using the while command. It creates a loops that does
not stop until the condition is evaluated as false. If you create a condition
that never evaluates to false it will stay in an infinite loop. An example of
an infinite loop is this: /while {1 = 1} {say doh!} This while will never stop
executing and the program will appear locked up. The idea behind the while is
to create a condition that uses variables. Somewhere in the commands portion
you would set a variable causing the loop to fail.
]]
function MMCompat.doWhile(condition, cmds)
end

--[[
Format: /showme {text}

Showme will echo the text to the terminal screen. The text is not sent to the
mud.

   * {text} Text to display.
]]
function MMCompat.doShowme(m)
  -- we're given a table of matches, because of the conditional regex matches[2] will be an empty
  -- string if no {}'s are used
  local str = (m[2] ~= "") and m[2] or m[3]

  if MMCompat.isDebug then
    printDebug("\nin doShowme\n", true)

    echo("doShowme matches:\n")
    display(m)
  end

  --echo("doShowme '" .. str .. "'\n")
  feedTriggers("\n"..str.."\n")
  --decho(ansi2decho(str))
end


function MMCompat.config()

    for _,v in ipairs(MMCompat.scriptAliases) do
        killAlias(v)
    end

    MMCompat.scriptAliases = {}

    -- pattern that matches 2 or 3 groups of {}'s, 3rd being optional
    -- with the 2nd possibly containing a nested command also with {}'s
    local nested3MatchPattern = [[(?:{(.+?)}|(\w+))\s+(?:{(.+?)}|(.+?))\s*(?:{((?:[^{}]|\{[^{}]*\})*)})?$]]

    MMCompat.functions = {
      {name="action", pattern="^/action "..nested3MatchPattern, cmd=[[MMCompat.makeAction(matches)]]},
      --{name="alias", pattern=[[^/alias (?:{(.+?)}|(\w+))\s+(?:{(.*?)}|(.*?))\s*(?:{(.*)})?$]], cmd=[[MMCompat.makeAlias(matches)]]},
      {name="alias", pattern="^/alias "..nested3MatchPattern, cmd=[[MMCompat.makeAlias(matches)]]},
      {name="event", pattern=[[^/event {(.*?)}\s*{(\d+?)}\s*{(.*?)}\s*(?:{(.*)})?$]], cmd=[[MMCompat.makeEvent(matches[2], matches[3], matches[4], matches[5])]]},
      {name="if", pattern=[[^/if {(.+?)}\s*{(.+?)}\s*(?:{(.+)})?$]], cmd=[[MMCompat.doIf(matches[2], matches[3], matches[4])]]},
      {name="itemadd", pattern=[[^/itema(?:dd)? (?:{(\w+)}|(\w+))\s+(?:{(.*?)}|(.*?))$]], cmd=[[MMCompat.itemAdd(matches)]]},
      {name="listadd", pattern=[[^/lista(?:dd)? (?:{(\w+)}|(\w+))\s+(?:{(.*?)}|(.*?))$]], cmd=[[MMCompat.listAdd(matches[2], matches[3])]]},
      {name="itemdelete", pattern=[[^/itemd(?:elete)? (?:{(\w+)}|(\w+))\s+(?:{(.*?)}|(.*?))$]], cmd=[[MMCompat.itemDelete(matches[2], matches[3])]]},
      {name="listcopy", pattern=[[^/listc(?:opy)? (?:{(\w+)}|(\w+))\s+(?:{(.*?)}|(.*?))$]], cmd=[[MMCompat.listCopy(matches[2], matches[3])]]},
      {name="listdelete", pattern=[[^/listd(?:elete)? (?:{(\w+)}|(\w+))$]], cmd=[[MMCompat.listDelete(matches[2])]]},
      {name="loop", pattern=[[^/loop {(.+?,\s*.+?)(?:,\s*(.+))?}\s*{(.+)}$]], cmd=[[MMCompat.doIf(matches[2], matches[3], matches[4])]]},
      {name="showme", pattern=[[^/showme (?:{(.+?)}|(.+?))$]], cmd=[[MMCompat.doShowme(matches)]]},
      {name="variable", pattern="^/var(?:iable)? "..nested3MatchPattern, cmd=[[MMCompat.makeVariable(matches)]]},
      {name="while", pattern=[[^/while {(.+?)}\s*{(.+)}$]], cmd=[[MMCompat.doIf(matches[2], matches[3])]]},
      --{name="", pattern=[[]], cmd=[[]]},
    }

    for _,v in pairs(MMCompat.functions) do
      local aliasId = tempAlias(v.pattern, v.cmd)
      cecho(string.format("\n<white>[<indian_red>MMCompat<white>] Loaded <LawnGreen>%s <white>command, id: <green>%d", v.name, aliasId))
      table.insert(MMCompat.scriptAliases, aliasId)
    end

end

if not MMCompat.isInitialized then
  MMCompat.config()
end

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