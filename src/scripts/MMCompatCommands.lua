function MMCompat.doChatCall(str)
    if not chatCall then
      MMCompat.error("MMCP is not implemented in this version of Mudlet")
      return
    end

    local foundAddress = false
    local address = ""
    local strText = str

    foundAddress, address, strText = MMCompat.findStatement(strText)

    if not foundAddress then
      MMCompat.error("Error parsing address from '"..str.."'")
      return
    end

    local foundPort = false
    local port = 4050

    foundPort, port, strText = MMCompat.findStatement(strText)

    if foundPort then
      port = tonumber(port)
    end

    local addressStr = MMCompat.referenceVariables(address, MMGlobals)
    local portStr = MMCompat.referenceVariables(port, MMGlobals)

    chatCall(addressStr, portStr)
  end

--[[
Format: /chat
Format: /chat {chat name} {text}
Format: /chat {reference number} {text}

Chat has two purposes. Without parameters it lists all the chat connections you
currently have. It is also used to chat privately with another user.

   * {chat name} The chat name of the person you want to send some text to.
   * {reference number} The number of the person you want to send some text to.
     The number is from the list of chat connections.
   * {text} The text to send.

Examples:

/chat
Displays all the chat connections you have.

/chat bosozoku Heya Boso!
Sends a private chat of "Heya Boso!" to Bosozoku.

/chat 1 Hi.
Sends a private chat of "Hi." to the first connection in your chat list.
]]
function MMCompat.doChat(str)
    if not chat then
        MMCompat.error("MMCP is not implemented in this version of Mudlet")
        return
    end

    local foundTarget = false
    local target = ""
    local strText = str

    foundTarget, target, strText = MMCompat.findStatement(strText)

    if not foundTarget then
        chatList()
        return
    end

    local foundMessage = false
    local message = strText

    local targetStr = MMCompat.referenceVariables(target, MMGlobals)
    local messageStr = MMCompat.referenceVariables(message, MMGlobals)

    chat(targetStr, messageStr)
end

function MMCompat.doChatAll(str)
    if not chatAll then
        MMCompat.error("MMCP is not implemented in this version of Mudlet")
        return
    end

    local messageStr = MMCompat.referenceVariables(str, MMGlobals)

    chatAll(messageStr)
end

function MMCompat.doChatName(str)
    if not chatName then
        MMCompat.error("MMCP is not implemented in this version of Mudlet")
        return
    end

    local strText = str
    local foundName = false
    local name = "MudletUser"

    foundName, name, strText = MMCompat.findStatement(strText)

    if not foundName then
        MMCompat.error("Error parsing chatName from '"..str.."'")
        return
    end

    local nameStr = MMCompat.referenceVariables(name, MMGlobals)

    chatName(nameStr)
end

function MMCompat.doEmoteAll(str)
    if not chatEmoteAll then
        MMCompat.error("MMCP is not implemented in this version of Mudlet")
        return
    end

    local messageStr = MMCompat.referenceVariables(str, MMGlobals)

    local emoteStr = "says, '" .. messageStr .. "'"
    chatEmoteAll(emoteStr)
end

function MMCompat.doUnChat(str)
    if not chatUnChat then
        MMCompat.error("MMCP is not implemented in this version of Mudlet")
        return
    end

    local foundTarget = false
    local target = ""
    local strText = str

    foundTarget, target, strText = MMCompat.findStatement(strText)

    if not foundTarget then
        MMCompat.error("Error parsing target from '"..str.."'")
        return
    end

    local targetStr = MMCompat.referenceVariables(target, MMGlobals)

    chatUnChat(targetStr)
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
--[[
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
  local thenCommands = MMCompat.parseCommands(thenCode, false, false)
  local elseCommands = MMCompat.parseCommands(elseCode, false, false)

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
]]

function MMCompat.doIf2(strText)
    local foundCondition = false
    local stmt = ""
    local foundThen = false
    local thenStmt = ""
    local foundElse = false
    local elseStmt = ""

    foundCondition, stmt, strText = MMCompat.findStatement(strText)
    foundThen, thenStmt, strText = MMCompat.findStatement(strText)
    foundElse, elseStmt, strText = MMCompat.findStatement(strText)

    local parsedCondition = "return " .. MMCompat.replaceVariables(stmt, false)

    if MMCompat.isDebug then
        if foundCondition then
        MMCompat.echo("ifCondition: " ..stmt)
        end

        if foundThen then
        MMCompat.echo("thenCondition: " ..thenStmt)
        end

        if foundElse then
        MMCompat.echo("elseCondition: " ..elseStmt)
        end

        MMCompat.echo(parsedCondition)
    end

    local result = MMCompat.executeString(parsedCondition)

    if result then
        if foundThen then
        expandAlias(thenStmt)
        end
    else
        if foundElse then
        expandAlias(elseStmt)
        end
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
--function MMCompat.doLoop(loopBounds, loopVar, cmds)
function MMCompat.doLoop(strText)
    --[[
    if MMCompat.isDebug then
        local dbgTbl = {
        loopBounds = loopBounds,
        loopVar = loopVar,
        cmds = cmds
        }

        MMCompat.debug("doLoop")
        display(dbgTbl)
    end
    ]]

    local foundBounds = false
    local loopBounds = ""

    foundBounds, loopBounds, strText = MMCompat.findStatement(strText)

    if not foundBounds then
        MMCompat.error("Error parsing loop bounds from '"..strText.."'")
        return
    end

    local foundCmds = false
    local cmdsStmt = ""

    foundCmds, cmdsStmt, strText = MMCompat.findStatement(strText)

    if not foundCmds then
        MMCompat.error("Error parsing loop commands from '"..strText.."'")
        return
    end

    local function split_string(input)
        local result = {}
        for value in string.gmatch(input, '([^,]+)') do
        local trimmed_value = tonumber(value:match("^%s*(.-)%s*$"))
        table.insert(result, trimmed_value)
        end
        return result
    end

    local loopArgs = split_string(loopBounds)

    if MMCompat.isDebug then
        display(loopArgs)
    end

    local loopVar = (loopArgs[3] ~= "") and loopArgs[3] or "LoopCount"
    MMCompat.debug("adjusted loopVar: " .. loopVar)

    local loopStep = (loopArgs[1] <= loopArgs[2]) and 1 or -1

    for lv = loopArgs[1], loopArgs[2], loopStep do
        MMGlobals[loopVar] = lv
        if MMCompat.isDebug then
        display(MMGlobals)
        end

        MMCompat.debug("iteration "..lv.." cmds: " .. cmdsStmt)

        expandQueue(cmdsStmt)
    end

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
function MMCompat.doWhile(strText)
    local foundCondition = false
    local conditionStmt = ""
    local foundCmds = false
    local cmdsStmt = ""

    foundCondition, conditionStmt, strText = MMCompat.findStatement(strText)

    if not foundCondition then
        MMCompat.error("Error parsing conditional statement from '"..strText.."'")
        return
    end

    foundCmds, cmdsStmt = MMCompat.findStatement(strText)

    if not foundCmds then
        MMCompat.error("Error parsing commands statement from '"..strText.."'")
        return
    end

    local parsedCondition = "return " .. MMCompat.replaceVariables(conditionStmt, false)

    MMGlobals['whileLoopCount'] = 1
    while MMCompat.executeString(parsedCondition) do
        if MMCompat.isDebug then
        display(MMGlobals)
        end

        MMCompat.debug("iteration "..MMGlobals['whileLoopCount'].." cmds: " .. cmdsStmt)

        expandQueue(cmdsStmt)

        -- Protection from infinite loops, user may edit maxWhileLoop var to adjust
        -- the maximum number of loops a while may execute
        MMGlobals['whileLoopCount'] = MMGlobals['whileLoopCount'] + 1
        if MMGlobals['whileLoopCount'] > MMCompat.maxWhileLoop then
            MMCompat.warning("Breaking while loop after 100 iterations")
            break
        end
    end
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
        --printDebug("\nin doShowme\n", true)

        echo("doShowme matches:\n")
        display(m)
    end

    local varStr = MMCompat.referenceVariables(str, MMGlobals)

    --echo("doShowme '" .. str .. "'\n")
    feedTriggers(varStr.."\n")
    echo("")
end

--[[
Format: /listadd {list name} {group name}

Creates a new user defined list.

   * {list name} Name of the list you want to create.
   * {group name} Optional, see the user guide for help on groups.
]]
function MMCompat.listAdd(name, group)
    MMGlobals[name] = MMGlobals[name] or {}

    local tblIdx = MMCompat.index_of(MMCompat.save.lists, name)
    if not tblIdx then
        table.insert(MMCompat.save.lists, name)
    end
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

    local tblIdx = MMCompat.index_of(MMCompat.save.lists, toName)
    if not tblIdx then
        table.insert(MMCompat.save.lists, toName)
    end
end

--[[
Format: /clearlist {list}
Format: /clearlist {reference number}

Removes all the items from the specified list.

   * {list} Name of the list you want to clear.
   * {reference number} Reference number of the list you want to clear.
]]
function MMCompat.clearList(list)
    MMCompat[list] = {}
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

    local tblIdx = MMCompat.index_of(MMCompat.save.lists, name)
    if tblIdx then
        table.remove(MMCompat.save.lists, name)
    end
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

function MMCompat.makeAction(m)

    local ptrn = (m[2] ~= "") and m[2] or m[3]
    local cmds = m[4]
    local group = m[5] or nil

    local pattern = MMCompat.parseCaptures(ptrn)
    local commands = MMCompat.parseCommands(cmds, true, false)

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
      MMCompat.warning("Action with the name '<green>" .. ptrn .. "<white>' already exists")
      return
    end

    local treeGroup = MMCompat.createParentGroup(group, "trigger", "MMActions")

    if MMCompat.isDebug then
      echo("Creating trigger '" .. ptrn .. "'\n")

      echo("commands:\n")
      display(commands)
    end

    permRegexTrigger(ptrn, treeGroup, {pattern}, commands)
  end


  function MMCompat.makeAction2(strText)

    local foundPattern = false
    local ptrn = ""

    foundPattern, ptrn, strText = MMCompat.findStatement(strText)

    if not foundPattern then
      MMCompat.error("Error parsing action pattern from '"..strText.."'")
      return
    end

    MMCompat.debug("Found action pattern '"..ptrn.."'")

    local foundCommands = false
    local cmdsStmt = ""

    MMCompat.debug("Looking for commands in '"..strText.."'")

    foundCommands, cmdsStmt, strText = MMCompat.findStatement(strText)

    if not foundCommands then
      MMCompat.error("Error parsing action commands from '"..strText.."'")
      return
    end

    MMCompat.debug("Found action commands '"..cmdsStmt.."'")

    local foundGroup = false
    local group = ""

    MMCompat.debug("Looking for group in '"..strText.."'")

    foundGroup, group, strText = MMCompat.findStatement(strText)

    local pattern = MMCompat.parseCaptures(ptrn)
    local commands = MMCompat.parseCommands(cmdsStmt, true, false)

    if MMCompat.isDebug then
      local tbl = {
        tFoundGroup = foundGroup,
        tGroup = group,
        tPattern = ptrn,
        tParsedPattern = pattern,
        tCmds = cmdsStmt,
        tItemType = "trigger",
        tCommands = commands
      }

      display(tbl)
    end

    if exists(ptrn, "trigger") ~= 0 then
      MMCompat.warning("Action with the name '<green>" .. ptrn .. "<white>' already exists")
      return
    end

    local treeGroup = MMCompat.createParentGroup(group, "trigger", "MMActions")

    MMCompat.debug("Creating trigger '" .. ptrn .. "'")

    if MMCompat.isDebug then
      echo("commands:\n")
      display(commands)
    end

    local trigId = permRegexTrigger(ptrn, treeGroup, {pattern}, commands)

    MMCompat.debug("trigId: " .. trigId)

    local actionTbl = {
        pattern = ptrn,
        cmd = cmdsStmt,
        group = treeGroup
    }

    local tblIdx = table.index_of(MMCompat.save.actions, actionTbl)
    if not tblIdx then
        table.insert(MMCompat.save.actions, actionTbl)
    end
end

--[[
function MMCompat.makeAlias(m)

    if MMCompat.isDebug then
      echo("\nin makeAlias(), matches:\n")
      display(m)
    end

    local ptrn = (m[2] ~= "") and m[2] or m[3]
    local cmds = m[4]
    local group = m[5] or nil

    if MMCompat.isDebug then
      MMCompat.debug("makeAlias before parse")
      display(MMGlobals)
      echo("\n")
    end

    local pattern = "^/"..MMCompat.parseCaptures(ptrn)
    local commands = MMCompat.parseCommands(cmds, true, false)

    if MMCompat.isDebug then
      local tbl = {
        tGroup = group,
        tPattern = ptrn,
        tParsedPattern = pattern,
        tCmds = cmds,
        tItemType = "alias"
      }

      MMCompat.debug("makeAlias after parse")
      display(tbl)
      echo("\n")
      display(MMGlobals)
    end

    if exists(ptrn, "alias") ~= 0 then
      MMCompat.echo("Alias with the name '<green>" .. ptrn .. "<white>' already exists")
      return
    end

    -- Create group 'group' under group 'parentGroup', if group exists
    local treeGroup = MMCompat.createParentGroup(group, "alias", "MMAliases")

    permAlias(ptrn, treeGroup, pattern, commands)
end
--]]

function MMCompat.makeAlias2(str)
    local strText = str
    local foundPattern = false
    local aliasPattern = ""

    foundPattern, aliasPattern, strText = MMCompat.findStatement(strText)

    if not foundPattern then
        MMCompat.error("Unable to parse alias name from '"..str.."'")
        return
    end

    local foundCommand = false
    local aliasCommands = ""

    foundCommand, aliasCommands, strText = MMCompat.findStatement(strText)

    if not foundCommand then
        MMCompat.error("Unable to parse alias command from '"..str.."'")
        return
    end

    local foundGroup = false
    local aliasGroup = ""

    foundGroup, aliasGroup, strText = MMCompat.findStatement(strText)

    local pattern = "^"..MMCompat.parseCaptures(aliasPattern)
    local commands = MMCompat.parseCommands(aliasCommands, true, false)

    if MMCompat.isDebug then
      local tbl = {
        tGroup = aliasGroup,
        tPattern = aliasPattern,
        tParsedPattern = pattern,
        tCmds = aliasCommands,
        tItemType = "alias"
      }

      MMCompat.debug("makeAlias after parse")
      display(tbl)
      echo("\n")
      display(MMGlobals)
    end

    if exists(aliasPattern, "alias") ~= 0 then
      MMCompat.warning("Alias with the name '<green>" .. aliasPattern .. "<white>' already exists")
      return
    end

    -- Create group 'group' under group 'parentGroup', if group exists
    local treeGroup = MMCompat.createParentGroup(aliasGroup, "alias", "MMAliases")

    permAlias(aliasPattern, treeGroup, pattern, commands)

    local aliasTbl = {
        pattern = aliasPattern,
        cmd = aliasCommands,
        group = treeGroup
    }

    local tblIdx = table.index_of(MMCompat.save.aliases, aliasTbl)
    if not tblIdx then
        table.insert(MMCompat.save.aliases, aliasTbl)
    end
end

function MMCompat.editAlias(str)

end

-- name, frequency, commands, group
function MMCompat.makeEvent(name, freq, cmds, group)
    local commands = MMCompat.parseCommands(cmds, false, false)

    local itemType = "timer"
    local itemParent = "MMEvents"

    if exists(name, itemType) ~= 0 then
      echo("Event with the name '" .. name .. "' already exists")
      return
    end

    MMCompat.createParentGroup(group, itemType, itemParent)

    permTimer(name, group, freq, commands)

    local eventTbl = {
        name = name,
        freq = freq,
        group = group
    }

    local tblIdx = table.index_of(MMCompat.save.events, eventTbl)
    if not tblIdx then
        table.insert(MMCompat.save.events, eventTbl)
    end
end

--[[
Format: /event {name} {frequency} {event actions} {group}

Event causes some actions to be taken when a certain amount of time has passed.
{frequency} is the amount of time in seconds to pass before firing the event.
You can create as many events as you like.  Duplicate frequencies are valid;
so you could create several events to fire every 10 seconds.

   * {name} The name of the event.
   * {frequency} The number of seconds until the event fires.
   * {event actions} The commands to do when the event fires.
   * {group} Optional, see the user guide for help on groups.

Typing /event by itself will list all the events you have defined. When you
list the events you are also shown the time left before the event fires.

001: {Jumper} {F:30} {T:14} {jump}
This is an example of an event listing. This first parameter is the name of the
event.  F: shows you the frequency you have set for the event.  T: shows how
much time is left before the event gets fired. The last part contains the event
actions to be taken when the event is fired.

/event {Jumper} {30} {jump}
This will create an event called Jumper that jumps every 30 seconds.
]]
function MMCompat.makeEvent2(str)
    local strText = str
    local foundName = false
    local eventName = ""

    if str and str ~= "" then
        foundName, eventName, strText = MMCompat.findStatement(strText)
    end

    if not foundName then
        MMCompat.listEvents()
        return
    end

    local foundFreq = false
    local eventFreq = ""

    foundFreq, eventFreq, strText = MMCompat.findStatement(strText)

    if not foundFreq then
        MMCompat.error("Unable to parse event frequency from '"..str.."'")
        return
    end

    local foundActions = false
    local eventActions = ""

    foundActions, eventActions, strText = MMCompat.findStatement(strText)

    if not foundActions then
        MMCompat.error("Unable to parse event actions from '"..str.."'")
        return
    end

    local foundGroup = false
    local eventGroup = nil

    foundGroup, eventGroup, strText = MMCompat.findStatement(strText)

    local commands = MMCompat.parseCommands(eventActions, false, false)

    local itemType = "timer"
    local itemParent = "MMEvents"
    if eventGroup ~= "" then
        itemParent = eventGroup
    end

    if exists(eventName, itemType) ~= 0 then
      MMCompat.echo("Event with the name '" .. eventName .. "' already exists")
      return
    end

    local treeGroup = MMCompat.createParentGroup(eventGroup, itemType, itemParent)

    permTimer(eventName, treeGroup, eventFreq, commands)

    enableTimer(eventName)

    local eventTbl = {
        name = eventName,
        freq = eventFreq,
        cmd = eventActions,
        group = treeGroup
    }

    local tblIdx = table.index_of(MMCompat.save.events, eventTbl)
    if not tblIdx then
        table.insert(MMCompat.save.events, eventTbl)
    end
end

function MMCompat.listEvents()
    echo("# Defined Events:\n")
    for k, v in pairs(MMCompat.save.events) do
        if exists(v.name, "timer") ~= 0 then
            local evtTime = remainingTime(v.name) or v.freq

            echo(string.format("%03s: {%s} {F:%d} {T:%d} {%s}\n",
                tonumber(k), v.name, v.freq, evtTime, v.cmd))

        end
    end
end

-- name, value, group
--[[
function MMCompat.makeVariable(m)

    local name = (m[2] ~= "") and m[2] or m[3]
    local value = (m[4] ~= "") and m[4] or m[5]
    local group = (m[6] ~= "") and m[6] or ""
  
    if MMCompat.isDebug then
      display(m)
      echo(string.format("\nname: %s, value: %s, group: %s\n", name, value, group))
    end
  
    local valueType = type(value)
  
    local valueNumeric = tonumber(value)
    if valueNumeric then
      MMGlobals[name] = valueNumeric
    elseif valueType == "string" then
      MMGlobals[name] = value
    else
      MMCompat.warning(string.format("Value type (%s) is not a number or string!", valueType))
    end
end
--]]

function MMCompat.makeVariable2(strText)

    local foundVar = false
    local varName = ""

    MMCompat.debug("makeVariable2 finding VAR, strText:")
    if MMCompat.isDebug then
        display(strText)
        echo("\n")
        display(MMGlobals)
        echo("\n")
    end
    foundVar, varName, strText = MMCompat.findStatement(strText)

    if not foundVar then
      MMCompat.error("Error parsing variable name from '" .. strText.."'")
      return
    end

    MMCompat.debug("varName: " .. varName)

    local foundVal = false
    local varValue = ""

    MMCompat.debug("makeVariable2 finding VAL, strText:")
    if MMCompat.isDebug then
      display(strText)
      echo("\n")
      display(MMGlobals)
      echo("\n")
    end
    foundVal, varValue, strText = MMCompat.findStatement(strText)

    if not foundVal then
      MMCompat.error("Error parsing variable value from '" .. strText.."'")
      return
    end

    MMCompat.debug("varValue: " .. varValue)

    local foundGroup = false
    local varGroup = ""

    if MMCompat.isDebug then
      if strText ~= "" then
        MMCompat.debug("makeVariable2 finding GROUP, strText:")
        display(strText)
        echo("\n")
      end
    end
    foundGroup, varGroup, strText = MMCompat.findStatement(strText)

    if not foundGroup then
      varGroup = ""
    end

    if MMCompat.isDebug then
      display(strText)
      echo(string.format("\nname: %s, value: %s, group: %s\n", varName, varValue, varGroup))
    end

    local valueType = type(varValue)

    local valueNumeric = tonumber(varValue)
    if valueNumeric then
      MMGlobals[varName] = valueNumeric
    elseif valueType == "string" then
      MMGlobals[varName] = varValue
    else
      MMCompat.warning(string.format("Value type (%s) is not a number or string!", valueType))
    end

    local varIdx = table.index_of(MMCompat.save.variables, varName)
    if not varIdx then
        table.insert(MMCompat.save.variables, varName)
    end

end

function MMCompat.doUnVariable(str)
    local foundVar = false
    local varName = ""
    local strText = str

    MMCompat.debug("doUnVariable finding VAR, strText:")
    if MMCompat.isDebug then
        display(strText)
        echo("\n")
        display(MMGlobals)
        echo("\n")
    end
    foundVar, varName, strText = MMCompat.findStatement(strText)

    if not foundVar then
      MMCompat.error("Error parsing variable name from '" .. strText.."'")
      return
    end

    MMCompat.debug("varName: " .. varName)

    MMGlobals[varName] = nil
    local varIdx = table.index_of(MMCompat.save.variables, varName)
    table.remove(MMCompat.save.variables, varIdx)
end

function MMCompat.doEmpty(str)
    local foundVar = false
    local varName = ""
    local strText = str

    MMCompat.debug("doEmpty finding VAR, strText:")
    if MMCompat.isDebug then
        display(strText)
        echo("\n")
        display(MMGlobals)
        echo("\n")
    end
    foundVar, varName, strText = MMCompat.findStatement(strText)

    if not foundVar then
      MMCompat.error("Error parsing variable name from '" .. strText.."'")
      return
    end

    MMCompat.debug("varName: " .. varName)

    MMGlobals[varName] = ""

    local varIdx = table.index_of(MMCompat.save.variables, varName)
    if not varIdx then
        table.insert(MMCompat.save.variables, varName)
    end
end

function MMCompat.doEditVariable(str)
    local foundVar = false
    local varName = ""
    local strText = str

    MMCompat.debug("doEmpty finding VAR, strText:")
    if MMCompat.isDebug then
        display(strText)
        echo("\n")
        display(MMGlobals)
        echo("\n")
    end
    foundVar, varName, strText = MMCompat.findStatement(strText)

    if not foundVar then
      MMCompat.error("Error parsing variable name from '" .. strText.."'")
      return
    end

    MMCompat.debug("varName: " .. varName)

    clearCmdLine()
    appendCmdLine("/variable {"..varName.."} {"..MMGlobals[varName].."}")
end

--[[

Format: /array {array name} {rows} {group name}
Format: /array {array name} {rows,columns} {group name}

Array lets you create both single and two dimensional arrays. If you are not
familiar with arrays, you can think of them like a spreadsheet. A single
dimensional array would have only 1 column, and as many rows as you specify. A
two dimensional array would have both rows and columns. Each cell in the array
would be accessed by giving a row and a column number. In the case of single
dimensional array, only a row number is needed. Each cell can hold data like a
variable.

   * {array name} The name of the array.
   * {rows} When creating a single dimensional array, the number of rows.
   * {rows,columns} For creating a two dimensional array.
   * {group name} This is optional, see the user guide for help with groups.

Examples:

/array {Targets} {3}
This would create an array called Targets. The array can hold up to 3 items.

/array {Grid} {5,5}
This creats a two dimensional array, or a grid. The grid has 5 rows, with 5
columns in each row.

The /array command now initializes all array elements in the new array to empty.
When arrays are written to script files elements which are empty are not written
into the script file.

See /assign for assigning values and @getarray or @arr or @a for retrieving values
]]
function MMCompat.makeArray(str)
    local strText = str
    local foundName = false
    local arrayName = ""

    foundName, arrayName, strText = MMCompat.findStatement(strText)

    if not foundName then
        MMCompat.error("Unable to parse array name from '"..str.."'")
        return
    end

    local foundBounds = false
    local arrayBounds = ""

    foundBounds, arrayBounds, strText = MMCompat.findStatement(strText)

    if not foundBounds then
        MMCompat.error("Unable to parse array bounds from '"..str.."'")
        return
    end

    MMCompat.debug("bounds: " .. arrayBounds)

    local foundGroup = false
    local arrayGroup = ""

    foundGroup, arrayGroup, strText = MMCompat.findStatement(strText)

    local arrayRows = nil
    local arrayCols = nil

    for row, col in arrayBounds:gmatch("(%d+)%s*,?%s*(%d*)") do
        arrayRows = tonumber(row)
        if col ~= "" then
            arrayCols = tonumber(col)
        end
        break
    end

    MMCompat.debug("rows: " .. arrayRows .. " cols: " ..arrayCols)

    local arrayTbl = {
        bounds = {rows=arrayRows, cols=arrayCols or 0},
        name = arrayName,
        group = arrayGroup
    }

    MMGlobals[arrayName] = {
        value = {}
    }

    local tblIdx = table.index_of(MMCompat.save.arrays, arrayTbl)
    if not tblIdx then
        table.insert(MMCompat.save.arrays, arrayTbl)
    end

end

--[[
Format: /assign {array name} {row} {value}
Format: /assign {array name} {row,column} {value}

Assign sets the value of a cell in an array.

   * {array name} The name of the array.
   * {row} For assigning cells in a single dimensional array. The number must be
     between 1 and the number of rows you created the array with.
   * {rows,columns} For assigning cells in a two dimensional array. The numbers
     must be between 1 and the number of rows and columns you created the array
     with.
   * {value} The text or number you want to assign to the cell.

Examples:

/assign {Targets} {1} {Soth}
This assigns the first cell in the array to hold the text "Soth".

/assign {Grid} {2,4} {16}
This assigns row 2, column 4 of the grid with a value of 16.

See /array for defining arrays
]]
function MMCompat.doAssign(str)
    local strText = str
    local foundName = false
    local arrayName = ""

    foundName, arrayName, strText = MMCompat.findStatement(strText)

    if not foundName then
        MMCompat.error("Unable to parse array name from '"..str.."'")
        return
    end

    local foundBounds = false
    local arrayBounds = ""

    foundBounds, arrayBounds, strText = MMCompat.findStatement(strText)

    if not foundBounds then
        MMCompat.error("Unable to parse array bounds from '"..str.."'")
        return
    end

    MMCompat.debug("bounds: " .. arrayBounds)

    local foundValue = false
    local arrayValue = ""

    foundValue, arrayValue, strText = MMCompat.findStatement(strText)

    if not foundValue then
        MMCompat.error("Unable to parse array value from '"..str.."'")
        return
    end

    local arrayRow = nil
    local arrayCol = nil

    for row, col in arrayBounds:gmatch("(%d+)%s*,?%s*(%d*)") do
        arrayRow = tonumber(row)
        if col ~= "" then
            arrayCol = tonumber(col)
        end
    end

    local found = MMCompat.findArray(arrayName, arrayRow, arrayCol)

    -- try to find array in arrays savelist
    --[[
    local found = false
    for k, v in pairs(MMCompat.save.arrays) do
        if v.name == arrayName then
            found = true
            -- check bounds
            if arrayRow > v.bounds.rows then
                MMCompat.error(string.format("Array '%s' row index out of bounds, given %d, bounds %d",
                    v.name, arrayRow, v.bounds.row))
                return
            end
            if v.bounds.cols and arrayCol and arrayCol > v.bounds.cols then
                MMCompat.error(string.format("Array '%s' col index out of bounds, given %d, bounds %d",
                    v.name, arrayCol, v.bounds.col))
                return
            end
            break
        end
    end
    --]]

    if not found then
        MMCompat.warning(string.format("Array '%s' not found", arrayName))
        return
    end

    MMGlobals[arrayName]['value'][arrayRow] = MMGlobals[arrayName]['value'][arrayRow] or {}

    if arrayCol then

        MMGlobals[arrayName]['value'][arrayRow][arrayCol] = arrayValue
    else
        MMGlobals[arrayName]['value'][arrayRow] = arrayValue
    end

end
