-- MudMaster Compatibility Script
-- 
-- use * to indicate an argument that must be provided
-- use ? to indicate an argument that is optional
-- use %# to indicate the appropriately numbered argument
-- use wait # to wait that many seconds, including decimal seconds, before continuing to the next command
--
-- use /alias or /trigger to show a list of all aliases or triggers managed by this script
-- use /delete alias # or /delete trigger # to delete that alias or trigger, using the number matching that shown on the list
-- 

-- Code adopted from user Jor'Mox on the Mudlet forums
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

local function parse_pattern(ptrn)
    ptrn = string.gsub(ptrn,"([^/])%*","%1(.*)")
    ptrn = string.gsub(ptrn,"^%*","(.*)")
    ptrn = string.gsub(ptrn,"([^/])%?","%1\\s*(.*)")
    ptrn = string.gsub(ptrn,"^%?%s*","(.-)\\s*")
    ptrn = string.gsub(ptrn,"%s+\\s%*","\\s*")
    ptrn = "^" .. ptrn .. "$"
    return ptrn
end


-- Function to replace %1, %2, etc., with named regex captures
local function parse_captures(pattern)
  local captures = {}

  -- Loop through the pattern and find all % followed by a number
  for match in string.gmatch(pattern, "%%(%d+)") do
      -- Create the named capture for each match
      local named_capture = string.format("(?<%s>.*)", match)
      -- Store the original and replacement in the table
      table.insert(captures, {original = "%" .. match, replacement = named_capture})
  end

  -- Replace all the found patterns in the original string
  for _, capture in ipairs(captures) do
      pattern = string.gsub(pattern, capture.original, capture.replacement)
  end

  return pattern
end


-- Function to replace $variables in the string
local function replace_variables(str, globals_table)

  -- Find all $variables and replace them in one pass
  for var_name in string.gmatch(str, "%$[%w_]+") do
    local key = var_name:sub(2)  -- Remove the $ symbol
    local value = globals_table[key] or var_name  -- Lookup the value in globals_table or keep the original
    local valueStr = "\"..MMGlobals['"..key.."']..\""
    str = string.gsub(str, var_name, valueStr)

    if MMCompat.isDebug then
      echo("var_name: " .. var_name .. "\n")
      echo("key: " .. key .. "\n")
      echo("replaced: " .. str .. "\n")
    end
  end

  return str
end

function MMCompat.assignGlobalMatches()
  for n=2, #matches do
    MMGlobals[n-1] = matches[n]
  end
end

local function parse_cmds(cmds)
  -- split commands by semicolon
  cmds = string.split(cmds,"%s*;%s*")

  display(cmds)

  -- Add code that puts all matches into MMGlobals
  local matchStr = [[MMCompat.assignGlobalMatches()]]

  echo("matchStr: " .. matchStr .. "\n")

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

  local expandedStr = replace_variables(str, MMGlobals)

  if MMCompat.isDebug then
    echo("expandedStr: " .. expandedStr .. "\n")
  end

  return matchStr .. "\n" .. expandedStr
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
  local pattern = parse_pattern(ptrn)
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


function MMCompat.config()

    for i,v in ipairs(MMCompat.scriptAliases) do
        killAlias(v)
    end

    MMCompat.scriptAliases = {}

    -- arguments are pattern, commands, group
    table.insert(MMCompat.scriptAliase, tempAlias([[^/action {(.*?)}\s*{(.*?)}\s*(?:{(.*)})?$]],
      [[MMCompat.makeAction(matches[2], matches[3], matches[4])]]))

    table.insert(MMCompat.scriptAliase, tempAlias([[^/alias {(.*?)}\s*{(.*?)}\s*(?:{(.*)})?$]],
      [[MMCompat.makeAlias(matches[2], matches[3], matches[4]]))

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


MMCompat.isInitialized = true