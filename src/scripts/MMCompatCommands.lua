MMCompat.add_command('call', {
    help = [[
Format: /call {address} {port}

Call establishes a link with another user using a client with a compatible
chat protocol, such as zMud, TinTin++, etc, as well as other MudMaster users.
If you are connected with another MudMaster user you can chat, transfer
commands and transfer files. The number of people you can be connected to at
one time is limited only by the number of socket connections windows will let
you have.

   * {address} The address of the person you wish to call. This can be either
     a named address or an IP address.
   * {port} The port is optional. If you don't specify a port number Mud
     Master will use a default of 4050.
]],
    pattern = [[^/call (.*)$]],
    func = [[MMCompat.doChatCall(matches[2])]]
})
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


MMCompat.add_command('chat', {
    help = [[
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
]],
    pattern = [[^/chat\s*(.*)$]],
    func = [[MMCompat.doChat(matches[2])]]
})
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


MMCompat.add_command('chatall', {
    help = [[
Format: /chatall {text}

Sends text to all of your chat connections.

   * {text} The text to send.

Example:

/chatall Hi.
]],
    pattern = [[^/chata(?:ll)? (.*)$]],
    func = [[MMCompat.doChatAll(matches[2])]]
})
function MMCompat.doChatAll(str)
    if not chatAll then
        MMCompat.error("MMCP is not implemented in this version of Mudlet")
        return
    end

    local messageStr = MMCompat.referenceVariables(str, MMGlobals)

    chatAll(messageStr)
end


MMCompat.add_command('chatname', {
    help = [[
Format: /chatname {name}

Sets your chat name. You must set a chat name before you can make any chat
calls.

   * {name} The name you wish to be known by.
]],
    pattern = [[^/chatn(?:ame)? (.*)$]],
    func = [[MMCompat.doChatName(matches[2])]]
})
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


MMCompat.add_command('emoteall', {
    help = [[
Format: /emoteall {text}

Sends an emote to all of your chat connections.

   * {text} The text to send.
]],
    pattern = [[^/emotea(?:ll)? (.*)$]],
    func = [[MMCompat.doEmoteAll(matches[2])]]
})
function MMCompat.doEmoteAll(str)
    if not chatEmoteAll then
        MMCompat.error("MMCP is not implemented in this version of Mudlet")
        return
    end
    local strText = str
    local text

    -- handle single string argument with or without curly brackets
    if string.sub(str, 1, 1) == '{' then
        local foundText = false
        foundText, text, strText = MMCompat.findStatement(strText)

        if not foundText then
            MMCompat.warning("Could not parse text to emote")
            return
        end

    else
        text = strText
    end

    local messageStr = MMCompat.referenceVariables(text, MMGlobals)

    local emoteStr = "says, '" .. messageStr .. "'"
    chatEmoteAll(emoteStr)
end


MMCompat.add_command('unchat', {
    help = [[
Format: /unchat {reference number}
Format: /unchat {chat name}

UnChat hangs up a chat connection.

   * {reference number} The number of the chat connection you want to hang
     up on.
   * {chat name} The name of the chat connection you want to hang up on.
]],
    pattern = [[^/unchat (.*)$]],
    func = [[MMCompat.doUnChat(matches[2])]]
})
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


MMCompat.add_command('if', {
    help = [[
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
]],
    pattern = [[^/if (.*)$]],
    func = [[MMCompat.doIf(matches[2])]]
})
function MMCompat.doIf(strText)
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

    MMCompat.disableLocalEcho()

    if result then
        if foundThen then
            expandAlias(thenStmt)
        end
    else
        if foundElse then
            expandAlias(elseStmt)
        end
    end

    MMCompat.restoreLocalEcho()
end


MMCompat.add_command('loop', {
    help = [[
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
]],
    pattern = [[^/loop (.*)$]],
    func = [[MMCompat.doLoop(matches[2])]]
})
function MMCompat.doLoop(strText)
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

    --[[
    local function split_string(input)
        local result = {}
        for value in string.gmatch(input, '([^,]+)') do
            local trimmed_value = tonumber(value:match("^%s*(.-)%s*$"))
            table.insert(result, trimmed_value)
        end
        return result
    end

    local loopArgs = split_string(loopBounds)
    --]]

    local refStr, anyMatch = MMCompat.referenceVariables(loopBounds, MMGlobals)

    if anyMatch then
        loopBounds = refStr
    end

    local loopArgs = {}
    for token in string.gmatch(loopBounds, "[^,]+") do
        MMCompat.debug("parsing token: " .. token)
        local trimmedToken = string.gsub(token, "%s+", "")
        MMCompat.debug("inserting token: " .. trimmedToken)
        table.insert(loopArgs, trimmedToken)
    end

    if MMCompat.isDebug then
        MMCompat.debug("loopBounds: " .. loopBounds)
        MMCompat.debug("loopArgs:\n")
        display(loopArgs)
    end

    local loopVar = (loopArgs[3] ~= "") and loopArgs[3] or "LoopCount"
    MMCompat.debug("adjusted loopVar: " .. loopVar)

    local loopStart = tonumber(loopArgs[1])
    local loopStop = tonumber(loopArgs[2])
    if not loopStart or not loopStop then

        MMCompat.error("Could not parse loop bounds from '"..loopBounds.."'")
        return
    end

    local loopStep = (loopStart <= loopStop) and 1 or -1

    MMCompat.disableLocalEcho()

    for lv = loopStart, loopStop, loopStep do
        MMGlobals[loopVar] = lv
        if MMCompat.isDebug then
            display(MMGlobals)
        end

        MMCompat.debug("iteration "..lv.." cmds: " .. cmdsStmt)

        expandAlias(cmdsStmt)
    end

    MMCompat.restoreLocalEcho()

end


MMCompat.add_command('while', {
    help = [[
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
]],
    pattern = [[^/while (.*)$]],
    func = [[MMCompat.doWhile(matches[2])]]
})
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

    MMCompat.disableLocalEcho()

    while MMCompat.executeString(parsedCondition) do
        if MMCompat.isDebug then
        display(MMGlobals)
        end

        MMCompat.debug("iteration "..MMGlobals['whileLoopCount'].." cmds: " .. cmdsStmt)

        expandAlias(cmdsStmt)

        -- Protection from infinite loops, user may edit maxWhileLoop var to adjust
        -- the maximum number of loops a while may execute
        MMGlobals['whileLoopCount'] = MMGlobals['whileLoopCount'] + 1
        if MMGlobals['whileLoopCount'] > MMCompat.maxWhileLoop then
            MMCompat.warning("Breaking while loop after 100 iterations")
            break
        end
    end

    MMCompat.restoreLocalEcho()
end


MMCompat.add_command('math', {
    help = [[
Format: /math {variable for result} {math expression}

The math command lets you perform mathematical equations and place the result in
a variable. Math does integer math only (no floating point).

   * {variable for result} The name of the variable to place the result in. If
     the variable doesn't exist it will be created.
   * {math expression} Mathematical expression to be evaluated.

Operator  Description
--------  -----------
()        Precedence
*         Multiplication
/         Division
%         Modulus
+         Addition
-         Subtraction

Anything enclosed in the parens will be evaulated first. Then all the
multiplication, division and modulus operators are evaulated left to right.
Then addition and subtraction are evaluated left to right.

/math and @Math() now supports floating point numbers if a decimal is seen in
the equation.

/math {result} {3 + 5 * 4}
Would place the number 23 in a variable called "result."

/math {result} {(3 + 5) * 4}
Would place the number 32 in a variable called "result."

/math {result} {$result + 1}
Adds 1 to variable "result."

/math {result} {5 % 3}
The modulus operator returns the remainder of a division as an integer. This
would place the number 2 in the variable "result." 5 divided by 3 leaves a
remainder of 2.

/math {result} {3 / 2.0}
Would place the number 1.6667 in a variable called "result." Because the
expression contains a floating point number it will return a floating point
number.
]],
    pattern = [[^/math (.*)$]],
    func = [[MMCompat.doMath(matches[2])]]
})
function MMCompat.doMath(str)
    local strText = str
    local foundVar = false
    local varName = ""

    foundVar, varName, strText = MMCompat.findStatement(strText)

    if not foundVar then
        MMCompat.warning("Unable to parse variable name")
        return
    end

    local foundExp = false
    local expStr = ""

    foundExp, expStr, strText = MMCompat.findStatement(strText)

    if not foundExp then
        MMCompat.warning("Unable to parse variable name")
        return
    end

    local mathResult = MMCompat.procMath(expStr)

    local varTbl = {
        name = varName,
        group = ""
    }

    MMGlobals[varName] = mathResult

    local varIdx = MMCompat.findVariableTableIdx(varTbl)
    if not varIdx then
        table.insert(MMCompat.save.variables, varTbl)
        MMCompat.saveData()
    end

end


MMCompat.add_command('showme', {
    help = [[
Format: /showme {text}

Showme will echo the text to the terminal screen. The text is not sent to the
mud.

    * {text} Text to display.
]],
    pattern = [[^/showme (.*)$]],
    func = [[MMCompat.doShowme(matches[2])]]
})
function MMCompat.doShowme(str)
    MMCompat.debug("doShowme")
    local strText = str
    local foundText = false
    local text = ""

    
    if string.sub(str, 1, 1) == '{' then
        foundText, text, strText = MMCompat.findStatement(strText)

        if not foundText then
            MMCompat.warning("Could not parse text to show")
            return
        end

    else
        text = strText
    end

    local varStr = MMCompat.referenceVariables(text, MMGlobals)

    --echo("doShowme '" .. str .. "'\n")
    feedTriggers(varStr.."\n")
    echo("")
end


local is_int = function(n)
    return (type(n) == "number") and (math.floor(n) == n)
end


MMCompat.add_command('listadd', {
    help = [[
Format: /listadd {list name} {group name}

Creates a new user defined list.

   * {list name} Name of the list you want to create.
   * {group name} Optional, see the user guide for help on groups.
]],
    pattern = [[^/lista(?:dd)? (.*)$]],
    func = [[MMCompat.doListAdd(matches[2])]]
})
function MMCompat.doListAdd(str)
    local strText = str
    local foundName = false
    local listName = ""

    foundName, listName, strText = MMCompat.findStatement(strText)

    if not foundName then
        MMCompat.warning("Could not parse list name")
        return
    end

    local foundGroup = false
    local groupName = ""

    foundGroup, groupName, strText = MMCompat.findStatement(strText)


    local listTbl = {
        name = listName,
        count = 0,
        group = groupName,
        data = {}
    }

    local tblIdx = MMCompat.findListTableIdx(listTbl)
    if not tblIdx then
        table.insert(MMCompat.save.lists, listTbl)
        MMCompat.saveData()
    else
        MMCompat.warning("List with that name already exists!")
    end
end


MMCompat.add_command('listcopy', {
    help = [[
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
]],
    pattern = [[^/listc(?:opy)? (.*)$]],
    func = [[MMCompat.doListCopy(matches[2])]]
})
function MMCompat.doListCopy(str)
    local strText = str
    local foundFromName = false
    local listFromName = ""

    foundFromName, listFromName, strText = MMCompat.findStatement(strText)

    if not foundFromName then
        MMCompat.warning("Could not parse list name")
        return
    end

    local foundToName = false
    local listToName = ""
    local foundSort = false
    local listSort = "a"

    foundToName, listToName, strText = MMCompat.findStatement(strText)

    if not foundToName then
        listToName = listFromName .. "Copy"
    else
        foundSort, listSort, strText = MMCompat.findStatement(strText)

        if foundSort then
            if string.lower(listSort) ~= 'd' and string.lower(listSort) ~= 'd' then
                listSort = 'a'
            end
        end
    end

    local listTbl = findListByNameOrId(listFromName)
 
    if not listTbl then
        return
    end

    local copyTbl = table.deepcopy(listTbl)
    copyTbl.name = listToName

    if foundSort then
        if listSort == 'a' then
            table.sort(copyTbl.data)
        else
            table.sort(copyTbl.data, function(a, b) return a > b end)
        end
    end

    local tblIdx = MMCompat.findListTableIdx(copyTbl)
    if not tblIdx then
        table.insert(MMCompat.save.lists, copyTbl)
        MMCompat.saveData()
    end
end


MMCompat.add_command('clearlist', {
    help = [[
Format: /clearlist {list}
Format: /clearlist {reference number}

Removes all the items from the specified list.

   * {list} Name of the list you want to clear.
   * {reference number} Reference number of the list you want to clear.
]],
    pattern = [[^/clearl(?:ist)? (.*)$]],
    func = [[MMCompat.doClearList(matches[2])]]
})
function MMCompat.doClearList(str)
    local strText = str
    local foundName = false
    local listName = ""

    foundName, listName, strText = MMCompat.findStatement(strText)

    if not foundName then
        MMCompat.warning("Could not parse list name")
        return
    end

    local listTbl = findListByNameOrId(listName)
    if not listTbl then
        return
    end

    listTbl.data = {}
    listTbl.count = 0
end


MMCompat.add_command('listdelete', {
    help = [[
Format: /listdelete {list name}
Format: /listdelete {list number}

Deletes a user defined list and any items in the list.

    * {list name} The name of the list you want to delete.
    * {list number} The number of the list you want to delete.
]],
    pattern = [[^/listd(?:elete)? (.*)$]],
    func = [[MMCompat.doListDelete(matches[2])]]
})
function MMCompat.doListDelete(str)
    local strText = str
    local foundName = false
    local listName = ""

    foundName, listName, strText = MMCompat.findStatement(strText)

    if not foundName then
        MMCompat.warning("Could not parse list name")
        return
    end

    local listTbl = findListByNameOrId(listName)
    if not listName then
        return
    end

    local tblIdx = MMCompat.findListTableIdx(listTbl)
    if tblIdx then
        table.remove(MMCompat.save.lists, tblIdx)
        MMCompat.push_undo(listTbl, "list")
        MMCompat.saveData()
    end
end


MMCompat.add_command('lists', {
    help = [[
Format: /lists

Displays all the user lists you have defined and how many items are in each
list.
]],
    pattern = [[^/lists$]],
    func = [[MMCompat.doLists()]]
})
function MMCompat.doLists()
    echo("# Defined Lists:\n")
    for k, v in pairs(MMCompat.save.lists) do

        echo(string.format("%03s: %s(%d) {%s}\n",
            tonumber(k), v.name, v.count, v.group))

    end
end


MMCompat.add_command('listitems', {
    help = [[
Format: /listitems {list name}
Format: /listitems {list number}

Displays all the items in a particular list.

    * {list name} The name of the list of items you want to see.
    * {list number} The number of the list of items you want to see.
]],
    pattern = [[^/listi(?:tems)? (.*)$]],
    func = [[MMCompat.doListItems(matches[2])]]
})
function MMCompat.doListItems(str)
    local strText = str
    local foundName = false
    local listName = ""

    foundName, listName, strText = MMCompat.findStatement(strText)

    listName = string.lower(listName)

    if not foundName then
        MMCompat.error("Unable to parse list id/name from '"..str.."'")
        return
    end

    local listTbl = findListByNameOrId(listName)
    if not listTbl then
        return
    end

    cecho(string.format("Items in list [%s](%d):\n", listTbl.name, listTbl.count))

    for k, v in pairs(listTbl.data) do
        echo(string.format("%03d: %s\n", tonumber(k), v))
    end
end


MMCompat.add_command('itemadd', {
    help = [[
Format: /itemadd {list name} {item text}
Format: /itemadd {list number} {item text}

Adds a text string to a user defined list. Lists are sorted by order input.

    * {list name} The name of the list to add the item to.
    * {list number} The number of the list to add the item to.
    * {item text} The text to add to the list.
]],
    pattern = [[^/itema(?:dd)? (.*)$]],
    func = [[MMCompat.doItemAdd(matches[2])]]
})
function MMCompat.doItemAdd(str)
    local strText = str
    local foundName = false
    local listName = ""

    foundName, listName, strText = MMCompat.findStatement(strText)

    if not foundName then
        MMCompat.warning("Could not find list by that name")
        return
    end

    local foundItem = false
    local itemName = ""
    foundItem, itemName, strText = MMCompat.findStatement(strText)

    if not foundItem then
        MMCompat.warning("Could not parse item name")
        return
    end

    itemName = string.lower(itemName)

    local listTbl = findListByNameOrId(listName)

    if not listTbl then
        return
    end

    listTbl.data = listTbl.data or {}

    table.insert(listTbl.data, itemName)

    listTbl.count = listTbl.count + 1
end


MMCompat.add_command('itemdelete', {
    help = [[
Format: /itemdelete {list name} {item text}
Format: /itemdelete {list name} {item number}
Format: /itemdelete {list number} {item text}
Format: /itemdelete {list number} {item number}

Deletes an item from a user defined list.

    * {list name} The name of the list to delete the item from.
    * {list number} The number of the list to delete the item from.
    * {item text} The text of the item to delete.
    * {item number} The number of the item to delete.
]],
    pattern = [[^/itemd(?:elete)? (.*)$]],
    func = [[MMCompat.doItemDelete(matches[2])]]
})
function MMCompat.doItemDelete(str)
    local strText = str
    local foundName = false
    local listName = ""

    foundName, listName, strText = MMCompat.findStatement(strText)

    if not foundName then
        MMCompat.warning("Could not parse list name")
        return
    end

    local foundItem = false
    local itemName = ""
    foundItem, itemName, strText = MMCompat.findStatement(strText)

    if not foundItem then
        MMCompat.warning("Could not parse item name or id")
        return
    end

    listName = string.lower(listName)

    -- find the list
    local listTbl = findListByNameOrId(listName)

    if not listTbl then
        return
    end

    listTbl.data = listTbl.data or {}
    
    -- find the item
    local itemNum = tonumber(itemName)
    if itemNum then
        -- remove item by number
        table.remove(listTbl.data, itemNum)
    else
        -- remove item by name
        local itemIdx = table.index_of(listTbl.data, itemName)

        if itemIdx then
            table.remove(listTbl.data, itemIdx)
        end
    end

    listTbl.count = listTbl.count - 1

end


MMCompat.add_command('action', {
    help = [[
Format: /action {text pattern} {commands} {group name}

Action tells the client to look for a specific string of text from the mud and
to execute a command or multiple commands when it finds it. Typing /action by
itself will list all of the actions you have defined.

   * {text pattern} This is the text to look for to trigger the action.
   * {commands} The commands are the actions you want to take when the action
     is triggered.
   * {group name} This is an optional parameter. See the user guide for help on
     groups.

Examples:

/action {You are hungry.} {take food bag;}
This is the most basic form of an action. It sees the text "You are hungry."
and then sends the commands "take food bag" and "eat food" to the mud.

/action {^You are hungry.} {take food bag;eat food}
You can 'anchor' an action by starting it with a caret (^). When an action is
anchored the text to search for must be at the beginning of the line.

/action {%0 looks at you.} {say Hi $0}
%0-%9 are substitution variables that you can use in the trigger side of an
action. They work like a wildcard character but store the text the wildcard
represents for your use. If the mud sent the text "Arithon looks at you." it
would send the command "say Hi Arithon" back. You can use up to 10 (0-9)of
these variables to help you match a text pattern.
]],
    pattern = [[^/action\s*(.*)$]],
    func = [[MMCompat.makeAction(matches[2])]]
})
function MMCompat.makeAction(strText)

    if not strText or strText == "" then
        MMCompat.listActions()
        return
    end

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

    --if exists(ptrn, "trigger") ~= 0 then
    --  MMCompat.warning("Action with the name '<green>" .. ptrn .. "<white>' already exists")
    --  return
    --end

    MMCompat.initTopLevelGroup("MMActions", "trigger")

    local treeGroup = MMCompat.createParentGroup(group, "trigger", "MMActions")

    MMCompat.debug("Creating trigger '" .. ptrn .. "'")

    commands = commands .. "\nMMCompat.actionMatch = matches[1]"

    if MMCompat.isDebug then
      MMCompat.debug("commands:")
      display(commands)
    end

    local trigId = permRegexTrigger(ptrn, treeGroup, {pattern}, commands)

    MMCompat.debug("trigId: " .. trigId)

    local actionTbl = {
        pattern = ptrn,
        cmd = cmdsStmt,
        enabled = true,
        group = treeGroup
    }

    local tblIdx = MMCompat.findActionTableIdx(actionTbl)
    if not tblIdx then
        table.insert(MMCompat.save.actions, actionTbl)
        MMCompat.saveData()
    end

end


MMCompat.add_command('editaction', {
    help = [[
Format: /editaction {reference number}
Format: /editaction {text pattern}

Editaction allows you to easily edit an action without having to type the whole
thing over. You can either use the reference number shown when you list your
defined actions or the trigger text to edit it. The action is then placed in the
input line so that you have full editing capabilities.

   * {reference number} The number of the action you want to edit.
   * {text pattern} The trigger text of the action you want to edit.

** NOTE: Actions are stored and looked up by the trigger text. If you edit an
action and you change the trigger portion of that action when you press enter a
new action with that trigger will be created. This will not erase the action
that you had originally edited. If you wish to remove the original version you
need to use /unaction.
]],
    pattern = [[^/edita(?:ction)? (.*)$]],
    func = [[MMCompat.doEditAction(matches[2])]]
})
function MMCompat.doEditAction(str)
    local foundAction = false
    local actionName = ""
    local strText = str

    foundAction, actionName, strText = MMCompat.findStatement(strText)

    if not foundAction then
      MMCompat.error("Error parsing action name from '" .. str.."'")
      return
    end

    local actionTbl = MMCompat.findActionByNameOrId(actionName)

    if not actionTbl then
        MMCompat.warning("Unable to find action")
        return
    end

    clearCmdLine()
    appendCmdLine("/action {"..actionTbl.pattern.."} {"..actionTbl.cmd.."} {"..actionTbl.group.."}")
end


MMCompat.add_command('enableaction', {
    help = [[
Format: /enableaction {reference number}
Format: /enableaction {text pattern}

EnableAction allows you to turn actions on that have been disabled with
/disableaction.

   * {reference number} The number of the action to enable.
   * {text pattern} The trigger text of the action to enable.
]],
    pattern = [[^/disablea(?:ction)? (.*)$]],
    func = [[MMCompat.doDisableAction(matches[2])]]
})
function MMCompat.doEnableAction(str)
    local strText = str
    local foundName = false
    local ptrn = ""

    foundName, ptrn, strText = MMCompat.findStatement(strText)

    if not foundName then
        MMCompat.warning("Cannot parse action name")
        return
    end

    local actionTbl = MMCompat.findActionByNameOrId(ptrn)

    if not actionTbl then
        MMCompat.warning("Unable to find action")
        return
    end

    enableTrigger(actionTbl.pattern)
    actionTbl.enabled = true
end


MMCompat.add_command('disableaction', {
    help = [[
Format: /disableaction {reference number}
Format: /disableaction {text pattern}

Disables an action.

   * {reference number} The number of the action to disable.
   * {text pattern} The trigger text of the action to disable.
]],
    pattern = [[^/disablea(?:ction)? (.*)$]],
    func = [[MMCompat.doDisableAction(matches[2])]]
})
function MMCompat.doDisableAction(str)
    local strText = str
    local foundName = false
    local ptrn = ""

    foundName, ptrn, strText = MMCompat.findStatement(strText)

    if not foundName then
        MMCompat.warning("Cannot parse action name")
        return
    end

    local actionTbl = MMCompat.findActionByNameOrId(ptrn)

    if not actionTbl then
        MMCompat.warning("Unable to find action")
        return
    end

    disableTrigger(actionTbl.pattern)
    actionTbl.enabled = false
end


MMCompat.add_command('unaction', {
    help = [[
Format: /unaction {reference number}
Format: /unaction {text pattern}

Removes an action from your action list. You can either type the number of the
action which you see when you list the actions or an exact text match of the
trigger portion.

   * {reference number} The number of the action to remove.
   * {text pattern} The trigger text of the action to remove.
]],
    pattern = [[^/unaction (.*)$]],
    func = [[MMCompat.doUnAction(matches[2])]]
})
function MMCompat.doUnAction(str)
    local strText = str
    local foundName = false
    local ptrn = ""

    foundName, ptrn, strText = MMCompat.findStatement(strText)

    if not foundName then
        MMCompat.warning("Cannot parse action name")
        return
    end

    local actionTbl = MMCompat.findActionByNameOrId(ptrn)

    if not actionTbl then
        MMCompat.warning("Unable to find action")
        return
    end

    disableTrigger(actionTbl.pattern)

    local actionIdx = MMCompat.findActionTableIdx(actionTbl)
    if not actionIdx then
        MMCompat.warning("Unable to find action")
        return
    end

    table.remove(MMCompat.save.actions, actionIdx)
    MMCompat.saveData()
end


MMCompat.add_command('substitute', {
    help = [[
Format: /substitute {text pattern} {replacement text} {group name}

A substitute looks for text patterns in the same way that an action does. When
it finds a match it substitutes the text in the pattern with the replacement
text. 

If you use one or more pattern wildcards like %0 you can then use the matching
system variables like $0 as well as other variables in the replacement string

   * {text pattern} The text to substitute.
   * {replacement text} The text to display.
   * {group name} This is an optional parameter. See the user guide for help on
     groups.    
]],
    pattern = [[^/sub(?:stitute)? (.*)$]],
    func = [[MMCompat.makeSubstitute(matches[2])]]
})
function MMCompat.makeSubstitute(str)
    local strText = str
    local foundPattern = false
    local ptrn = ""

    foundPattern, ptrn, strText = MMCompat.findStatement(strText)

    if not foundPattern then
      MMCompat.error("Error parsing substitute pattern from '"..strText.."'")
      return
    end

    local foundReplacement = false
    local strReplace = ""

    foundReplacement, strReplace, strText = MMCompat.findStatement(strText)

    if not foundReplacement then
        MMCompat.error("Error parsing substitute replacement from '"..str.."'")
        return
    end

    local foundGroup = false
    local subGroup = ""

    foundGroup, subGroup, strText = MMCompat.findStatement(strText)

    local pattern = MMCompat.parseCaptures(ptrn)

    MMCompat.debug("Creating substitution '" .. ptrn .. "'")

    MMCompat.initTopLevelGroup("MMSubstitutions", "trigger")

    local treeGroup = MMCompat.createParentGroup(subGroup, "trigger", "MMSubstitutions")

    local commands = string.format("selectString(matches[1], 1) replace(\"%s\", true)",
                                strReplace)

    local trigId = permRegexTrigger(ptrn, treeGroup, {pattern}, commands)

    local subTbl = {
        pattern = ptrn,
        group = treeGroup
    }

    local tblIdx = MMCompat.findSubTableIdx(subTbl)
    if not tblIdx then
        table.insert(MMCompat.save.subs, subTbl)
        MMCompat.saveData()
    end
end


MMCompat.add_command('gag', {
    help = [[
Format: /gag {mask}

Adds a gag to the gag list. Before the client prints a line of text to the
screen it checks the gag list. If {mask} is found in a line of text that line
will not be printed.

   * {mask} This is the text pattern to search for to determine what lines of
     text to gag. The mask can be defined the same way you define the text
     pattern for an action-- using %0 through %9.

/gag {Geoff says}
Any lines that have the text "Geoff says" in them will not be seen.

/gag {You hear %0 shout}
]],
    pattern = [[^/gag (.*)$]],
    func = [[MMCompat.makeGag(matches[2])]]
})
function MMCompat.makeGag(str)
    local strText = str
    local foundPattern = false
    local ptrn = ""

    foundPattern, ptrn, strText = MMCompat.findStatement(strText)

    if not foundPattern then
      MMCompat.error("Error parsing gag pattern from '"..strText.."'")
      return
    end

    local pattern = MMCompat.parseCaptures(ptrn)

    MMCompat.debug("Creating gag '" .. ptrn .. "'")

    MMCompat.initTopLevelGroup("MMGags", "trigger")

    local trigId = permRegexTrigger(ptrn, "MMGags", {pattern}, [[deleteLine()]])

    local gagTbl = {
        pattern = ptrn,
        group = "MMGags"
    }

    local tblIdx = MMCompat.findGagTableIdx(gagTbl)
    if not tblIdx then
        table.insert(MMCompat.save.gags, gagTbl)
        MMCompat.saveData()
    end
end


local function rgbToHex(r,g,b)
    local rgb = (r * 0x10000) + (g * 0x100) + b
    return string.format("#%x", rgb)
end


MMCompat.add_command('highlight', {
    help = [[
Format: /highlight {mask} {foreground color, background color}

Adds a highlight to the highlight list. Before the client prints a line of
text to the screen it checks the highlight list. If {mask} is found in a
line of text the colors for that word or words are changed to colors that
you specify.

   * {mask} This is the text pattern to search for to determine what lines of
     text to highlight. The mask can be defined the same way you define the
     text pattern for an action -- using %0 through %9. If the mask does not
     contain any wildcards (%0 - %9) then just the word is highlighted. If the
     mask uses a wildcard, the whole line is changed to the color.
   * {color,color} The foreground and background color to change the text to.
     Valid color names are in the table below. If you don't specify a
     background color "back black" will be used.

Color Names

   Foreground Colors:
     black, blue, green, cyan, red, magenta, brown, light
     grey, dark grey, light blue, light green, light cyan, light
     red, light magenta, yellow, white

   Background Colors:
     back black, back blue, back green, back cyan, back
     red, back magenta, back brown, back light grey

/highlight {disarms you} {yellow}
Any time you see the text "disarms you" it will appear in yellow.

/highlight {You hear %0 shout} {white,back blue}
Since a wildcard was used in the mask, when the text is found the entire line
will be changed to white on blue.
]],
    pattern = [[^/high(?:light)? (.*)$]],
    func = [[MMCompat.makeHighlight(matches[2])]]
})
function MMCompat.makeHighlight(str)
    local strText = str
    local foundPattern = false
    local ptrn = ""

    foundPattern, ptrn, strText = MMCompat.findStatement(strText)

    if not foundPattern then
      MMCompat.error("Error parsing highlight pattern from '"..strText.."'")
      return
    end

    local foundColors = false
    local colors = ""

    foundColors, colors, strText = MMCompat.findStatement(strText)

    if not foundColors then
        MMCompat.error("Error parsing highlight colors from '"..str.."'")
        return
    end

    local fgColor = nil
    local bgColor = nil

    MMCompat.debug("colors:" ..colors)

    local fg, bg = colors:match("([a-zA-Z]*)%s*,?%s*([a-zA-Z ]*)%s*")

    -- Check if fgColor was captured
    if fg and fg ~= "" then
        fgColor = fg
    end

    -- Check if bgColor was captured and not empty
    if bg and bg ~= "" then
        bgColor = bg
    end

    -- Replace spaces with underscores in fgColor and bgColor
    if fgColor then
        fgColor = string.gsub(fgColor, "%s", "_")
    end

    if bgColor then
        -- Remove 'back' and the space, then replace remaining spaces with underscores
        bgColor = string.gsub(bgColor, "^back%s+", "")  -- Remove 'back' and the space
        bgColor = string.gsub(bgColor, "%s", "_")  -- Replace remaining spaces with underscores
    else
        bgColor = ""
    end

    MMCompat.debug("fgColor: " .. fgColor ..", bgColor: " .. bgColor)

    local pattern, anyCaptures = MMCompat.parseCaptures(ptrn)

    MMCompat.debug("Creating highlight '" .. ptrn .. "'")

    MMCompat.initTopLevelGroup("MMHighlights", "trigger")

    local commands = ""
    if anyCaptures then
        commands = "selectString(line, 1)"
    else
        commands = "selectString(\""..ptrn.."\", 1)"
    end

    -- color_table has name to RGB values
    local fgRGB = MMCompat.convertColorToRGB(fgColor, 'black')
    local bgRGB = MMCompat.convertColorToRGB(bgColor, 'black')

    commands = commands .. string.format(" setFgColor(%d,%d,%d)",
                            fgRGB[1], fgRGB[2], fgRGB[3])

    if bgColor ~= "" then
        commands = commands .. string.format(" setBgColor(%d,%d,%d)",
                                bgRGB[1], bgRGB[2], bgRGB[3])
    end

    commands = commands .. " resetFormat()"

    -- Create a trigger to highlight the word "pixie" for us
    --permSubstringTrigger("Highlight stuff", "General", {"pixie"},
    --[[selectString(line, 1) bg("yellow") resetFormat()]]
    --)

    -- Or another trigger to highlight several different things
    --permSubstringTrigger("Highlight stuff", "General", {"pixie", "cat", "dog", "rabbit"},
    --[[selectString(line, 1) fg ("blue") bg("yellow") resetFormat()]]
    --)

    if anyCaptures then
        permRegexTrigger(ptrn, "MMHighlights", {pattern}, commands)
    else
        permSubstringTrigger(ptrn, "MMHighlights", {pattern}, commands)
    end

    local highlightTbl = {
        pattern = ptrn,
        group = "MMHighlights"
    }

    local tblIdx = MMCompat.findHighlightTableIdx(highlightTbl)
    if not tblIdx then
        table.insert(MMCompat.save.highlights, highlightTbl)
        MMCompat.saveData()
    end

end


MMCompat.add_command('alias', {
    help = [[
Format: /alias {shortcut} {commands} {group name}

An alias lets you define some "shortcut" text to execute a command or commands.
Your alias list is checked each time you press enter to send some text to the
mud. If the text you typed is found in your alias list the text from the
commands side of the alias is sent instead.  An alias is only replaced if it is
the first text typed on a line.

   * {alias name} This is the shortcut text you want to be able to type to
     execute commands.
   * {commands} The commands to execute when the alias name is typed.
   * {group name} This is an optional parameter. See the user guide on groups
     for help.

Examples:

/alias {eat} {take food bag;gobble food}
If you typed "eat" on the input line the commands "take food bag" and "gobble
food" would be sent to the mud instead.

/alias {targ %0} {/var Target $0}
You can also use the variable %0 to represent the text typed after the alias
shortcut. In this case the alias is used to quickly set a targeting variable.
Typing "targ Vecna" would set a variable called "Target" to "Vecna"
]],
    pattern = [[^/alias\s*(.*)$]],
    func = [[MMCompat.makeAlias(matches[2])]]
})
function MMCompat.makeAlias(str)

    if not str or str == "" then
        MMCompat.listAliases()
        return
    end

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

    MMCompat.initTopLevelGroup("MMAliases", "alias")

    -- Create group 'group' under group 'parentGroup', if group exists
    local treeGroup = MMCompat.createParentGroup(aliasGroup, "alias", "MMAliases")

    MMCompat.debug("makeAlias: commands: '"..commands.."'")

    permAlias(aliasPattern, treeGroup, pattern, commands)

    local aliasTbl = {
        pattern = aliasPattern,
        cmd = aliasCommands,
        enabled = true,
        group = treeGroup
    }

    local tblIdx = MMCompat.findAliasTableIdx(aliasTbl)
    if not tblIdx then
        table.insert(MMCompat.save.aliases, aliasTbl)
        MMCompat.saveData()
    end
end


MMCompat.add_command('disablealias', {
    help = [[
Format: /disablealias {reference number}
Format: /disablealias {alias name}

Disables an alias.

   * {reference number} The number of the alias to disable.
   * {text pattern} The name of the alias to disable.
]],
    pattern = [[^/disablea(?:lias)? (.*)$]],
    func = [[MMCompat.doDisableAlias(matches[2])]]
})
function MMCompat.doDisableAlias(str)
    local strText = str
    local foundName = false
    local aliasName = ""

    foundName, aliasName, strText = MMCompat.findStatement(strText)

    if not foundName then
        MMCompat.warning("Unable to parse alias name")
        return
    end

    local aliasTbl, aliasIdx = MMCompat.findAliasByNameOrId(aliasName)

    if not aliasTbl then
        MMCompat.warning("Could not find alias")
        return
    end

    aliasTbl.enabled = false
    disableAlias(aliasTbl.pattern)
end


MMCompat.add_command('enablealias', {
    help = [[
Format: /enablealias {reference number}
Format: /enablealias {alias name}

EnableAlias allows you to turn aliases on that have been disabled with
/disablealias.

   * {reference number} The number of the alias to enable.
   * {text pattern} The name of the alias to enable.
]],
    pattern = [[^/enablea(?:lias)? (.*)$]],
    func = [[MMCompat.doEnableAlias(matches[2])]]
})
function MMCompat.doEnableAlias(str)
    local strText = str
    local foundName = false
    local aliasName = ""

    foundName, aliasName, strText = MMCompat.findStatement(strText)

    if not foundName then
        MMCompat.warning("Unable to parse alias name")
        return
    end

    local aliasTbl, aliasIdx = MMCompat.findAliasByNameOrId(aliasName)

    if not aliasTbl then
        MMCompat.warning("Could not find alias")
        return
    end

    aliasTbl.enabled = true
    enableAlias(aliasTbl.pattern)
end


MMCompat.add_command('editalias', {
    help = [[
Format: /editalias {reference number}
Format: /editalias {alias name}

Editalias allows you to easily edit an alias without having to type the whole
thing over. You can either use the reference number shown when you list your
defined aliases or the shortcut text to edit it. The alias is then placed in the
input line so that you have full editing capabilities.

   * {reference number} The number of the alias you want to edit.
   * {alias name} The name of the alias you want to edit.

** NOTE: Aliases are stored and looked up by the shortcut text. If you edit an
alias and change the shortcut portion of that alias when you press enter a new
alias will be created. This will not erase the alias that you had originally
edited. If you wish to remove the original version you need to use /unalias.
]],
    pattern = [[^/editalias (.*)$]],
    func = [[MMCompat.doEditAlias(matches[2])]]
})
function MMCompat.doEditAlias(str)
    local foundAlias = false
    local aliasName = ""
    local strText = str

    foundAlias, aliasName, strText = MMCompat.findStatement(strText)

    if not foundAlias then
      MMCompat.error("Error parsing alias name from '" .. str.."'")
      return
    end

    local aliasTbl = MMCompat.findAliasByNameOrId(aliasName)

    if not aliasTbl then
        MMCompat.warning("Unable to find alias")
        return
    end

    clearCmdLine()
    appendCmdLine("/alias {"..aliasTbl.name.."} {"..aliasTbl.cmd.."} {"..aliasTbl.group.."}")
end


MMCompat.add_command('unalias', {
    help = [[
Format: /unalias {reference number}
Format: /unalias {alias name}

Remove an alias from your alias list. You can either type the number of the
alias which you see when you list the aliases or an exact text match of the
shortcut.

   * {reference number} The number of the alias you want to remove.
   * {alias name} The name of the alias you want to remove.
]],
    pattern = [[^/unalias (.*)$]],
    func = [[MMCompat.doUnAlias(matches[2])]]
})
function MMCompat.doUnAlias(str)
    local strText = str
    local foundName = false
    local aliasName = ""

    foundName, aliasName, strText = MMCompat.findStatement(strText)

    if not foundName then
        MMCompat.warning("Unable to parse alias name")
        return
    end

    local aliasTbl, aliasIdx = MMCompat.findAliasByNameOrId(aliasName)

    if not aliasTbl then
        MMCompat.warning("Could not find alias")
        return
    end

    table.remove(MMCompat.save.aliases, aliasIdx)
    MMCompat.saveData()

    disableAlias(aliasTbl.pattern)
end


MMCompat.add_command('event', {
    help = [[
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
]],
    pattern = [[^/event\s*(.*)?$]],
    func = [[MMCompat.makeEvent(matches[2])]]
})
function MMCompat.makeEvent(str)
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

    MMCompat.initTopLevelGroup("MMEvents", "timer")

    local treeGroup = MMCompat.createParentGroup(eventGroup, itemType, itemParent)

    permTimer(eventName, treeGroup, eventFreq, commands)

    enableTimer(eventName)

    local eventTbl = {
        name = eventName,
        freq = eventFreq,
        cmd = eventActions,
        group = treeGroup
    }

    local tblIdx = MMCompat.findEventTableIdx(eventTbl)
    if not tblIdx then
        table.insert(MMCompat.save.events, eventTbl)
        MMCompat.saveData()
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


MMCompat.add_command('fireevent', {
    help = [[
Format: /fireevent {event number}
Format: /fireevent {event name}

FireEvent causes an event to be fired before the time has elapsed. This also
resets the time elapsed to 0 for this event.

   * {event number} The number of the event to fire.
   * {event name} The name of the event to fire.

/fireevent 1
Would fire the first event in the event list. Also the time elapsed is set
back to 0.
]],
    pattern = [[^/fireevent (.*)$]],
    func = [[MMCompat.doFireEvent(matches[2])]]
})
function MMCompat.doFireEvent(str)
    local strText = str
    local foundEvent = false
    local eventName = ""

    foundEvent, eventName, strText = MMCompat.findStatement(strText)

    if not foundEvent then
        MMCompat.warning("Could not parse event name")
        return
    end

    eventName = string.lower(eventName)

    local eventNum = tonumber(eventName)
    if eventNum then
        for k, v in pairs(MMCompat.save.events) do
            if tonumber(k) == eventNum then
                disableTimer(v.name)
                enableTimer(v.name)
            end
        end
    else
        for k, v in pairs(MMCompat.save.events) do
            if string.lower(v.name) == eventName then
                disableTimer(v.name)
                enableTimer(v.name)
            end
        end
    end
end


MMCompat.add_command('resetevent', {
    help = [[
Format: /resetevent {event number}
Format: /resetevent {event name}
Format: /resetevent *

ResetEvent causes the time elapsed for an event to be reset back to 0. If
instead of passing an event number you pass an asterisk instead, all events
will be reset. You might want to reset all events if you are trying to get
several events to fire at the same time. If you define two events, each to
fire every 10 seconds they are most likely not going to fire at exactly the
same time (since created them at different times). If you reset all the events
they would both be reset to fire in 10 seconds and would fire at the same time
from then on.

   * {event number} The number of the event you want to reset.
   * {event name} The name of the event you want to reset.
   * * Will reset all of the events.
]],
    pattern = [[^/resetevent (.*)$]],
    func = [[MMCompat.doResetEvent(matches[2])]]
})
function MMCompat.doResetEvent(str)
    local strText = str
    local foundEvent = false
    local eventName = ""

    foundEvent, eventName, strText = MMCompat.findStatement(strText)

    if not foundEvent then
        MMCompat.warning("Could not parse event name")
        return
    end

    local allEvents = false
    if eventName == '*' then
        allEvents = true
    else
        eventName = string.lower(eventName)
    end

    local eventNum = tonumber(eventName)
    if eventNum then
        for k, v in pairs(MMCompat.save.events) do
            if allEvents or tonumber(k) == eventNum then
                disableTimer(v.name)
                enableTimer(v.name)
            end
        end
    else
        for k, v in pairs(MMCompat.save.events) do
            if allEvents or string.lower(v.name) == eventName then
                disableTimer(v.name)
                enableTimer(v.name)
            end
        end
    end

end


MMCompat.add_command('seteventtime', {
    help = [[
Format: /seteventtime {event number} {new time}
Format: /seteventtime {event name} {new time}

Changes the frequency of which an event fires. It also resets the time elapsed.

   * {event number} The number of the event you want to set.
   * {event name} The name of the event you want to set.
   * {new time} The new frequency of the event.
]],
    pattern = [[^/reseteventtime (.*)$]],
    func = [[MMCompat.doResetEventTime(matches[2])]]
})
function MMCompat.doResetEventTime(str)
    local strText = str
    local foundEvent = false
    local eventName = ""

    foundEvent, eventName, strText = MMCompat.findStatement(strText)

    if not foundEvent then
        MMCompat.warning("Could not parse event name")
        return
    end

    local foundTime = false
    local eventTime = ""

    foundTime, eventTime, strText = MMCompat.findStatement(strText)

    if not foundTime then
        MMCompat.warning("Could not parse event time")
        return
    end

    local eventFreq = tonumber(eventTime)
    if not eventFreq then
        MMCompat.warning("Could not parse event time")
        return
    end

    eventName = string.lower(eventName)
    local eventTbl = nil

    local eventNum = tonumber(eventName)
    if eventNum then
        for k, v in pairs(MMCompat.save.events) do
            if tonumber(k) == eventNum then
                eventTbl = v
                break
            end
        end
    else
        for k, v in pairs(MMCompat.save.events) do
            if string.lower(v.name) == eventName then
                eventTbl = v
                break
            end
        end
    end

    if not eventTbl then
        MMCompat.warning("Cannot find event")
        return
    end

    disableTimer(eventTbl.name)
    eventTbl.freq = eventFreq
    enableTimer(eventTbl.name)
end


MMCompat.add_command('disableevent', {
    help = [[
Format: /disableevent {reference number}
Format: /disableevent {event name}

DisableEvent allows you to turn individual events off. You can see which events
you have disabled when you list all of your defined events. Disabled events will
have an asterisk right after their reference number.

    * {reference number} The number of the event to disable.
    * {event name} The name of the event to disable.
]],
    pattern = [[^/disableevent (.*)$]],
    func = [[MMCompat.doUnEvent(matches[2])]]
})


MMCompat.add_command('unevent', {
    help = [[
Format: /unevent {event number}
Format: /unevent {event name}

This command removes an event from the eventlist.

***Note*** In Mudlet we cannot delete GUI timers via the Lua interface, well
can only disable the timer, which this function does instead of removing the
event.

   * {reference number} The number of the event you want to remove.
   * {event name} The name of the event you want to remove.
]],
    pattern = [[^/unevent (.*)$]],
    func = [[MMCompat.doUnEvent(matches[2])]]
})
function MMCompat.doUnEvent(str)
    local strText = str
    local foundName = false
    local eventName = ""

    foundName, eventName, strText = MMCompat.findStatement(strText)

    eventName = string.lower(eventName)

    if not foundName then
        MMCompat.error("Unable to parse event id/name from '"..str.."'")
        return
    end

    --if they supplied a number, find the event by that number
    local eventNum = tonumber(eventName)
    local eventTbl = nil
    if eventNum then
        for k, v in pairs(MMCompat.save.events) do
            if tonumber(k) == eventNum then
                eventTbl = v
                break
            end
        end

        if not eventTbl then
            MMCompat.warning("Unable to find event with id ".. eventNum)
            return
        end
    else
        for k, v in pairs(MMCompat.save.events) do
            if string.lower(v.name) == eventName then
                eventTbl = v
                break
            end
        end

        if not eventTbl then
            MMCompat.warning("Unable to find event with name '".. eventName.."'")
            return
        end
    end

    if exists(eventTbl.name, "timer") == 0 then
        MMCompat.warning("Unable to find Mudlet timer matching event...")
        MMCompat.warning("However it exists in your MM events list, we will create")
        MMCompat.warning("the event for you and leave its state disabled")

        -- Note this is much the same code as in makeEvent, consider a
        -- refactor for consolidation
        local commands = MMCompat.parseCommands(eventTbl.cmd, false, false)

        local itemType = "timer"
        local itemParent = "MMEvents"
        if eventTbl.group ~= "" then
            itemParent = eventTbl.group
        end

        MMCompat.initTopLevelGroup("MMEvents", "timer")

        local treeGroup = MMCompat.createParentGroup(eventTbl.group, itemType, itemParent)

        permTimer(eventName, treeGroup, eventTbl.freq, commands)

        local tblIdx = MMCompat.findEventTableIdx(eventTbl)
        if not tblIdx then
            table.insert(MMCompat.save.events, eventTbl)
            MMCompat.saveData()
        end
    end

    disableTimer(eventTbl.name)
end


MMCompat.add_command('variable', {
    help = [[
Format: /variable {variable name} {value} {group name}

The variable command adds a variable to your variable list and assigns it a
value. If the variable is already in the list the value is replaced with the new
value. A variable can be recalled by putting a @Var() around it's name, such as
"@Var(example)". You can also put a $ in front of the variable name to recall
it, such as "$example".

   * {variable name} What you want to name the variable.
   * {value} The value to assign to the variable.
   * {group name} This is an optional parameter. See the user guide for help on
     groups.

Example:

/variable {Target} {orc}
Adds a variable called Target to your list of variables and gives it a value of
"orc".

There are several variables that are defined by the client. The client will let
you if you insist, but you should probably not define variables with these
names. If you do your version of the variable will be found before the system
variable. For a list of system variables see the User Guide.
]],
    pattern = [[^/var(?:iable)? (.*)$]],
    func = [[MMCompat.makeVariable(matches[2])]]
})
function MMCompat.makeVariable(strText)
    MMCompat.debug("makeVariable")

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

    local processedVal, anyMatch = MMCompat.referenceVariables(varValue, MMGlobals)

    local varTbl = {
        name = varName,
        group = varGroup
    }

    MMGlobals[varName]= processedVal

    local varIdx = MMCompat.findVariableTableIdx(varTbl)
    if not varIdx then
        table.insert(MMCompat.save.variables, varTbl)
        MMCompat.saveData()
    end
end


MMCompat.add_command('unvariable', {
    help = [[
Format: /unvariable {reference number}
Format: /unvariable {variable name}

Removes a variable from your list of defined variables. You can either type the
number of the variable which you see when you list the variables or an exact
text match of the variable name.

   * {reference number} The number of the variable you want to remove.
   * {variable name} The name of the variable you want to remove.
]],
    pattern = [[^/unvar(?:iable)? (.*)$]],
    func = [[MMCompat.doUnVariable(matches[2])]]
})
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

    local varTbl = nil
    local varNum = tonumber(varName)
    varName = string.lower(varName)
    if varNum then
        for k, v in pairs(MMCompat.save.variables) do
            if tonumber(k) == varNum then
                varTbl = v
                break
            end
        end
    else
        for k, v in pairs(MMCompat.save.variables) do
            if string.lower(v.name) == varName then
                varTbl = v
                break
            end
        end
    end

    if not varTbl then
        MMCompat.warning("Could not find variable")
        return
    end

    MMGlobals[varName] = nil

    local varIdx = MMCompat.findVariableTableIdx(varTbl)
    if varIdx then
        table.remove(MMCompat.save.variables, varIdx)
        MMCompat.push_undo(varTbl, "var")
        MMCompat.saveData()
    end
end


MMCompat.add_command('empty', {
    help = [[
Format: /empty {variable name}

Empty creates a variable with an empty string (a string with no data in it).

   * {variable name} The name of the variable to create or set to empty.
]],
    pattern = [[^/empty (.*)$]],
    func = [[MMCompat.doEmpty(matches[2])]]
})
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

    local varTbl = nil
    local varNum = tonumber(varName)
    varName = string.lower(varName)
    if varNum then
        for k, v in pairs(MMCompat.save.variables) do
            if tonumber(k) == varNum then
                varTbl = v
                break
            end
        end
    else
        for k, v in pairs(MMCompat.save.variables) do
            if string.lower(v.name) == varName then
                varTbl = v
                break
            end
        end
    end

    if not varTbl then
        MMCompat.warning("Could not find variable")
        return
    end

    MMGlobals[varName] = ""

    local varIdx = MMCompat.findVariableTableIdx(varTbl)
    if not varIdx then
        table.insert(MMCompat.save.variables, varTbl)
        MMCompat.saveData()
    end
end


MMCompat.add_command('editvariable', {
    help = [[
Format: /editvariable {variable text or number}
Format: /editvariable {reference number}

Places the variable in the edit bar.

   * {variable text} The name of the variable you want to edit.
   * {reference number} The number of the variable you want to edit.
]],
    pattern = [[^/editv(?:ariable)? (.*)$]],
    func = [[MMCompat.doEditVariable(matches[2])]]
})
function MMCompat.doEditVariable(str)
    local foundVar = false
    local varName = ""
    local strText = str

    foundVar, varName, strText = MMCompat.findStatement(strText)

    if not foundVar then
      MMCompat.error("Error parsing variable name from '" .. strText.."'")
      return
    end

    MMCompat.debug("varName: " .. varName)

    clearCmdLine()
    appendCmdLine("/variable {"..varName.."} {"..MMGlobals[varName].."}")
end

MMCompat.add_command('array', {
    help = [[
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

See <link: assign>assign</link> for assigning values and @getarray or @arr or @a for retrieving values
]],
    pattern = [[^/array (.*)$]],
    func = [[MMCompat.makeArray(matches[2])]]
})
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
        group = arrayGroup,
        data = {}
    }

    local tblIdx = MMCompat.findArrayTableIdx(arrayTbl)
    if not tblIdx then
        table.insert(MMCompat.save.arrays, arrayTbl)
        MMCompat.saveData()
    end

end

MMCompat.add_command('assign', {
    help = [[
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

See <link: array>array</link> for defining arrays
]],
    pattern = [[^/assign (.*)$]],
    func = [[MMCompat.doAssign(matches[2])]]
})
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

    local arrayTbl = MMCompat.findArray(arrayName, arrayRow, arrayCol)

    if not arrayTbl then
        MMCompat.warning(string.format("Array '%s' not found", arrayName))
        return
    end

    arrayTbl['data'][arrayRow] = arrayTbl['data'][arrayRow] or {}

    if arrayCol then
        arrayTbl['data'][arrayRow][arrayCol] = arrayValue
    else
        arrayTbl['data'][arrayRow] = arrayValue
    end

end


MMCompat.add_command('unarray', {
    help = [[
Format: /unarray {reference number}
Format: /unarray {array name}

Removes an array from your list of defined arrays. You can either type the
number of the array which you see when you list them or the name of the array.

   * {reference number} The number of the array you want to remove.
   * {array name} The name of the array you want to remove.
]],
    pattern = [[^/unarray (.*)$]],
    func = [[MMCompat.doUnArray(matches[2])]]
})
function MMCompat.doUnArray(str)
    local strText = str
    local foundName = false
    local arrayName = ""

    foundName, arrayName, strText = MMCompat.findStatement(strText)

    if not foundName then
        MMCompat.error("Unable to parse array name from '"..str.."'")
        return
    end

    local arrayTbl = nil
    arrayName = string.lower(arrayName)
    local arrayNum = tonumber(arrayName)
    if arrayNum then
        for k, v in pairs(MMCompat.save.arrays) do
            if tonumber(k) == arrayNum then
                arrayTbl = v
                break
            end
        end

        if not arrayTbl then
            MMCompat.warning("Unable to find array with id ".. arrayNum)
            return
        end
    else
        for k, v in pairs(MMCompat.save.arrays) do
            if string.lower(v.name) == arrayName then
                arrayTbl = v
                break
            end
        end

        if not arrayTbl then
            MMCompat.warning("Unable to find array with name '".. arrayName.."'")
            return
        end
    end

    local arrayIdx = MMCompat.findArrayTableIdx(arrayTbl)
    if arrayIdx then
        table.remove(MMCompat.save.arrays(arrayIdx))
        MMCompat.push_undo(arrayTbl, "array")
        MMCompat.saveData()
    end
end


MMCompat.add_command('read', {
    help = [[
Format: /read {drive:\filename.ext}
Format: /read {filename.ext}

Reads a saved command file.

   * {drive:\filename.ext} Name and path of the command file to read in.
   * {filename.ext} Name of the command file to read in.
]],
    pattern = [[^/read (.*)]],
    func = [[MMCompat.doRead(matches[2])]]
})
function MMCompat.doRead(str)
    local strText = str
    local foundFile = false
    local fileName = ""

    foundFile, fileName, strText = MMCompat.findStatement(strText)

    if not foundFile then
        MMCompat.error("Unable to parse filename from '"..str.."'")
        return
    end

    if not io.exists(fileName) then
        MMCompat.error("File does not exist '"..str.."'")
        return
    end

    local file = io.open(fileName, "r")

    if not file then
        MMCompat.error("Failed to open file!")
        return
    end

    MMCompat.isLoading = true

    MMCompat.disableLocalEcho()

    -- Read file line by line
    for line in file:lines() do
        expandAlias(line)
    end

    MMCompat.restoreLocalEcho()

    -- Close the file
    file:close()

    MMCompat.isLoading = false

    MMCompat.saveData()
end


MMCompat.add_command('zap', {
    help = [[
Format: /zap

Kills your connection to the mud.
]],
    pattern = [[^/zap$]],
    func = [[MMCompat.doZap()]]
})
function MMCompat.doZap()
    disconnect()
end


MMCompat.add_command('remark', {
    help = [[
Format: /remark {Your Text Here}

You can use /remark in your script files if you write them in external editors.
When loaded /remark lines will have no effect on your scripting and will not be
seen by the client.

*Remarks will NOT save if you save from MudMaster 2k6 to a script file. They
are only useful for external use.
]],
    pattern = [[^/remark (.*)$]],
    func = [[MMCompat.doRemark(matches[2])]]
})
function MMCompat.doRemark(str)
end


MMCompat.add_command('dll', {
    help = [[
Format: /dll

Shows all the user defined DLLs you have loaded.
]],
    pattern = [[^/dll$]],
    func = [[MMCompat.doDll()]]
})
function MMCompat.doDll()
end


MMCompat.add_command('loadlibrary', {
    help = [[
Format: /loadlibrary {dll name}
Format: /loadlibrary {drive:\folder\dll name}
Format: /loadlibrary {dll name} {drive:\folder\dll name}

Loads a user defined DLL.

***Note*** This has no effect in Mudlet, all common DLL actions
are implemented in Mudlet by default

   * {dll name} Filename of the DLL to load.
   * {drive:\folder\dll name} Path and filename of the DLL to load.

Examples:

/loadlibrary {math.dll}
This will attempt to load the math dll from the program folder. If it loads
successfully then it will load as "math.dll".

/loadlibrary {C:\Program Files\PortableMudMaster\math.dll}
This will attempt to load the math dll. If it loads successfully then it will load as "C:\Program Files\PortableMudMaster\math.dll".

/loadlibrary {math.dll} {C:\Program Files\PortableMudMaster\math.dll}
This will attempt to load the math dll. If it loads successfully then it will load as "math.dll".

Check the UserGuide for more information on Dll's.
]],
    pattern = [[^/loadl(?:ibrary)? (.*)$]],
    func = [[MMCompat.doLoadLibrary(matches[2])]]
})
function MMCompat.doLoadLibrary(str)
end


MMCompat.add_command('freelibrary', {
    help = [[
Format: /freelibrary {dll name}

Removes a user defined DLL from memory.

***Note*** This has no effect in Mudlet, all common DLL actions
are implemented in Mudlet by default

   * {dll name} Name of the user defined DLL.
]],
    pattern = [[^/freelib(?:rary)? (.*)$]],
    func = [[MMCompat.doFreeLibrary(matches[2])]]
})
function MMCompat.doFreeLibrary(str)
end


MMCompat.add_command('calldll', {
    help = [[
Format: /calldll {dll name} {function name} {parameters to send}

This command is used to call functions in a user defined DLL.

    * {dll name} The name of a loaded DLL to call.
    * {function name} The name of a function to call in the DLL.
    * {parameters to send} Information to send to the DLL function. Variables,
        functions, etc... are translated before being sent to the DLL.

Example:

/calldll {MyDLL} {MyFunction} {Some text to send and a variable $Var}
This will call the function "MyFunction" defined in the DLL "MyDLL" and send the
text "Some text..."

For more information please see the dll's help file.
]],
    pattern = [[^/calldll (.*)$]],
    func = [[MMCompat.doCallDll(matches[2])]]
})

function MMCompat.doCallDll(str)
    local strText = str
    local foundDllName = false
    local dllName = ""

    foundDllName, dllName, strText = MMCompat.findStatement(strText)

    if not foundDllName then
      MMCompat.error("Error parsing DLL name from '" .. str.."'")
      return
    end

    local foundFuncName = false
    local funcName = ""

    foundFuncName, funcName, strText = MMCompat.findStatement(strText)

    if not foundFuncName then
      MMCompat.error("Error parsing DLL function from '" .. str.."'")
      return
    end


    local foundParams = false
    local dllParams = ""

    foundParams, dllParams, strText = MMCompat.findStatement(strText)

    if not foundParams then
      MMCompat.error("Error parsing DLL parameters from '" .. str.."'")
      return
    end

    dllName = string.lower(dllName)
    funcName = string.lower(funcName)

    local saveDataTbl = nil
    local saveType = ""
    if dllName == "math.dll" then
        saveDataTbl = MMCompat.doMathDll(funcName, dllParams)
        saveType = "var"
    end

    if saveDataTbl then
        if saveType == "var" then
            local varIdx = MMCompat.findVariableTableIdx(saveDataTbl)
            if not varIdx then
                table.insert(MMCompat.save.variables, saveDataTbl)
                MMCompat.saveData()
            end
        end
        
    end

end


MMCompat.add_command('disablegroup', {
    help = [[
Format: /disablegroup {group name}

Disables all the defined commands in a group. All your events, aliases, actions,
bar items and macros belonging to the group will be disabled.

    * {group name} The name of the group to disable.
]],
    pattern = [[^/disableg(?:roup)? (.*)$]],
    func = [[MMCompat.doDisableGroup(matches[2])]]
})
function MMCompat.doDisableGroup(str)
    local strText = str
    local foundGroup = false
    local groupName = ""

    foundGroup, groupName, strText = MMCompat.findStatement(strText)

    if not foundGroup then
        MMCompat.error("Unable to parse group name from '"..str.."'")
        return
    end

    groupName = string.lower(groupName)

    -- find all aliases with that group
    for k, v in pairs(MMCompat.save.aliases) do
        if string.lower(v.group) == groupName then
            if exists(v.name, "alias") ~= 0 then
                disableAlias(v.name)
            else
                MMCompat.warning(string.format("Could not locate alias '%s' in group '%s' to disable",
                    v.name, groupName))
            end
        end
    end

    -- find all actions with that group
    for k, v in pairs(MMCompat.save.actions) do
        if string.lower(v.group) == groupName then
            if exists(v.name, "trigger") ~= 0 then
                disableAction(v.name)
            else
                MMCompat.warning(string.format("Could not locate action '%s' in group '%s' to disable",
                    v.name, groupName))
            end
        end
    end

    -- find all events with that group
    for k, v in pairs(MMCompat.save.events) do
        if string.lower(v.group) == groupName then
            if exists(v.name, "timer") ~= 0 then
                disableTimer(v.name)
            else
                MMCompat.warning(string.format("Could not locate timer '%s' in group '%s' to disable",
                    v.name, groupName))
            end
        end
    end
end


MMCompat.add_command('enablegroup', {
    help = [[
Format: /enablegroup {group name}

Enables all the defined commands in a group. All your events, aliases, actions,
bar items and macros belonging to the group will be enabled.

   * {group name} The name of the group to enable.
]],
    pattern = [[^/enableg(?:roup)? (.*)$]],
    func = [[MMCompat.doEnableGroup(matches[2])]]
})
function MMCompat.doEnableGroup(str)
    local strText = str
    local foundGroup = false
    local groupName = ""

    foundGroup, groupName, strText = MMCompat.findStatement(strText)

    if not foundGroup then
        MMCompat.error("Unable to parse group name from '"..str.."'")
        return
    end

    groupName = string.lower(groupName)

    -- find all aliases with that group
    for k, v in pairs(MMCompat.save.aliases) do
        if string.lower(v.group) == groupName then
            if exists(v.name, "alias") ~= 0 then
                enableAlias(v.name)
            else
                MMCompat.warning(string.format("Could not locate alias '%s' in group '%s' to enable",
                    v.name, groupName))
            end
        end
    end

    -- find all actions with that group
    for k, v in pairs(MMCompat.save.actions) do
        if string.lower(v.group) == groupName then
            if exists(v.name, "trigger") ~= 0 then
                enableAction(v.name)
            else
                MMCompat.warning(string.format("Could not locate action '%s' in group '%s' to enable",
                    v.name, groupName))
            end
        end
    end

    -- find all events with that group
    for k, v in pairs(MMCompat.save.events) do
        if string.lower(v.group) == groupName then
            if exists(v.name, "timer") ~= 0 then
                enableTimer(v.name)
            else
                MMCompat.warning(string.format("Could not locate timer '%s' in group '%s' to enable",
                    v.name, groupName))
            end
        end
    end
end

MMCompat.add_command('killgroup', {
    help = [[
Format: /killgroup {group name}

Removes all the stored commands from memory that belong to a certain group
(aliases, actions, events, etc...).

***Note*** In Mudlet there is no functionality to delete a GUI defined trigger
alias or timer, so in effect this just calls <link: disablegroup>disablegroup</link>

    * {group name} The name of the group you want to remove.
]],
    pattern = [[^/killg(?:roup)? (.*)$]],
    func = [[MMCompat.doKillGroup(matches[2])]]
})
function MMCompat.doKillGroup(str)
    MMCompat.doDisableGroup(str)
end

