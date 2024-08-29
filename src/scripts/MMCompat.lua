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


-- Function to replace %1, %2, etc., with named regex captures in the patterns
-- of triggers and aliases
local function parse_captures(pattern)
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
local function replace_variables(str, globals_table)

  local anyMatch = false

  -- Find all $variables and replace them in one pass
  for var_name in string.gmatch(str, "%$[%w_]+") do
    local key = var_name:sub(2)  -- Remove the $ symbol
    local value = globals_table[key] or var_name  -- Lookup the value in globals_table or keep the original
    local valueStr = "\"..MMGlobals['"..key.."']..\""
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


local function parse_cmds(cmds)
  -- split commands by semicolon
  cmds = string.split(cmds,"%s*;%s*")

  display(cmds)

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

  local expandedStr, anyMatchReplacements = replace_variables(str, MMGlobals)

  if MMCompat.isDebug then
    echo("expandedStr: " .. expandedStr .. "\n")
  end

  -- Add code that puts all matches into MMGlobals
  -- Only if the resulting code uses the matches table
  local matchStr = ""
  if anyMatchReplacements then
    matchStr = [[MMCompat.templateAssignGlobalMatches()]]
    matchStr = matchStr .. "\n"
  end

  return matchStr .. expandedStr
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
    if exists(group, itemType) == 0 then
      echo("Creating group " .. itemType .. "/" .. group.."\n")
      permGroup(group, itemType, itemParent)
      return group
    else
      echo("Group " .. itemType .. "/" .. group .." exists\n")
      return itemParent
    end

  end

  return itemParent
end


function MMCompat.makeAction(ptrn, cmds, group)
  local pattern = parse_captures(ptrn)
  local commands = parse_cmds(cmds)

  local itemType = "trigger"
  local itemParent = "MMActions"

  if MMCompat.isDebug then
    local tbl = {
      tGroup = group,
      tPattern = ptrn,
      tParsedPattern = pattern,
      tCmds = cmds,
      tItemType = itemType,
      tParent = itemParent,
      tCommands = commands
    }

    display(tbl)
  end

  if exists(ptrn, itemType) ~= 0 then
    echo("Action with the name '" .. ptrn .. "' already exists")
    return
  end

  local treeGroup = createParentGroup(group, itemType, itemParent)

  if MMCompat.isDebug then
    echo("Creating trigger '" .. ptrn .. "'\n")

    echo("commands:\n")
    display(commands)
  end

  permRegexTrigger(ptrn, treeGroup, {pattern}, commands)
end


function MMCompat.makeAlias(ptrn, cmds, group)
  local pattern = parse_captures(ptrn)
  local commands = parse_cmds(cmds)

  local itemType = "alias"
  local itemParent = "MMAliases"

  if MMCompat.isDebug then
    local tbl = {
      tGroup = group,
      tPattern = ptrn,
      tParsedPattern = pattern,
      tCmds = cmds,
      tItemType = itemType
    }

    display(tbl)
  end

  if exists(ptrn, itemType) ~= 0 then
    echo("Alias with the name '" .. ptrn .. "' already exists")
    return
  end

  createParentGroup(group, itemType, itemParent)

  permAlias(ptrn, group, pattern, commands)
end

-- name, frequency, commands, group
function MMCompat.makeEvent(name, freq, cmds, group)
  local commands = parse_cmds(cmds)

  local itemType = "timer"
  local itemParent = "MMEvents"

  if exists(name, itemType) ~= 0 then
    echo("Event with the name '" .. name .. "' already exists")
    return
  end

  createParentGroup(group, itemType, itemParent)

  permTimer(name, group, freq, commands)
end

-- name, frequency, commands, group
function MMCompat.makeVariable(name, value, group)
  MMGlobals[name] = value
end

function MMCompat.listAdd(name, group)
  MMGlobals[name] = MMGlobals[name] or {}
end

function MMCompat.itemAdd(name, text)
  MMGlobals[name] = MMGlobals[name] or {}
  table.insert(MMGlobals[name], text)
end

function MMCompat.listCopy(from, to)
  MMGlobals[from] = MMGlobals[from] or {}

  local toName = to and to or from.."Copy"

  MMGlobals[toName] = table.deepcopy(from)
end

function MMCompat.listDelete(name, text)
  MMGlobals[name] = MMGlobals[name] or {}
  table.insert(MMGlobals[name], text)
end

function MMCompat.itemDelete(name, text)
  MMGlobals[name] = MMGlobals[name] or {}
  table.insert(MMGlobals[name], text)
end


function MMCompat.config()

    for _,v in ipairs(MMCompat.scriptAliases) do
        killAlias(v)
    end

    MMCompat.scriptAliases = {}

    MMCompat.functions = {
      {name="action", pattern=[[^/action {(.*?)}\s*{(.*?)}\s*(?:{(.*)})?$]], cmd=[[MMCompat.makeAction(matches[2], matches[3], matches[4])]]},
      {name="alias", pattern=[[^/alias (?:{(\w+)}|(\w+))\s+(?:{(.*?)}|(.*?))\s*(?:{(.*)})?$$]], cmd=[[MMCompat.makeAlias(matches[2], matches[3], matches[4])]]},
      {name="event", pattern=[[^/event {(.*?)}\s*{(\d+?)}\s*{(.*?)}\s*(?:{(.*)})?$]], cmd=[[MMCompat.makeEvent(matches[2], matches[3], matches[4], matches[5])]]},
      {name="variable", pattern=[[^/var(?:iable)? (?:{(\w+)}|(\w+))\s+(?:{(.*?)}|(.*?))\s*(?:{(.*)})?$]], cmd=[[MMCompat.makeVariable(matches[2], matches[3], matches[4])]]},
      {name="listadd", pattern=[[^/listadd {(.*?)}\s*(?:{(.*)})?$]], cmd=[[MMCompat.listAdd(matches[2], matches[3])]]},
      {name="itemadd", pattern=[[^/itemadd {(.*?)}\s*{(.*?)}$]], cmd=[[MMCompat.itemAdd(matches[2], matches[3])]]},
      --{name="", pattern=[[]], cmd=[[]]},

    }

    for _,v in pairs(MMCompat.functions) do
      local aliasId = tempAlias(v.pattern, v.cmd)
      table.insert(MMCompat.scriptAliases, aliasId)
    end

    -- arguments are pattern, commands, group
    --table.insert(MMCompat.scriptAliases, tempAlias([[^/action {(.*?)}\s*{(.*?)}\s*(?:{(.*)})?$]],
    --  [[MMCompat.makeAction(matches[2], matches[3], matches[4])]]))

    --table.insert(MMCompat.scriptAliases, tempAlias([[^/alias {(.*?)}\s*{(.*?)}\s*(?:{(.*)})?$]],
    --  [[MMCompat.makeAlias(matches[2], matches[3], matches[4])]]))

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