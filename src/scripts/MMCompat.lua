-- MudMaster Compatibility Script
-- 
-- use %# to indicate an argument that must be provided
-- use $# to indicate the appropriately numbered argument

-- Code inspired from user Jor'Mox on the Mudlet forums
-- https://forums.mudlet.org/viewtopic.php?t=16462

MMCompat = MMCompat or {
  isInitialized = false,
  isDebug = false,
  isLoading = false,  -- flag to indicate if a sript is being loaded via /read
  scriptAliases = {},
  maxWhileLoop = 100, -- maximum number of loops allowed in a while statement
  version = "__VERSION__",
  helpAliasId = nil,
  helpEntries = 1,
  isLocalEcho = getConfig("showSentText"),
  wasLocalEcho = getConfig("showSentText"),
  save = {
    actions = {},
    aliases = {},
    arrays = {},
    events = {},
    gags = {},
    highlights = {},
    lists = {},
    macros = {},
    subs = {},
    variables = {},
    undoStack = {},
  },
  ansiBold = "\27[1m",
  ansiReset = "\27[0m",
  ansiReverse = "\27[7m",
  backColorTable = {
    [1] = "\27[44m",
    [2] = "\27[42m",
    [3] = "\27[46m",
    [4] = "\27[41m",
    [5] = "\27[45m",
    [6] = "\27[43m",
    [7] = "\27[7m",
    [8] = "\27[40m"
  },
  foreColorTable = {
    [1] = "\27[34m",        -- blue
    [2] = "\27[32m",        -- green
    [3] = "\27[36m",        -- cyan
    [4] = "\27[31m",        -- red
    [5] = "\27[35m",        -- magenta
    [6] = "\27[33m",        -- yellow
    [7] = "\27[37m",        -- white
    [8] = "\27[30m",        -- black
    [9] = "\27[1m\27[34m",  -- bold blue
    [10] = "\27[1m\27[32m", -- bold green
    [11] = "\27[1m\27[36m", -- bold cyan
    [12] = "\27[1m\27[31m", -- bold red
    [13] = "\27[1m\27[35m", -- bold magenta
    [14] = "\27[1m\27[33m", -- bold yellow
    [15] = "\27[1m\27[37m", -- bold white
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

  <orange>***Important Note***<reset>
  MudMaster uses a semicolon ; as a command separator, by default Mudlet uses two
  semicolons ;;. MMCompat will not function properly if you have changed your
  Mudlet command separator to a single semicolon!

<cyan>MudMaster Commands:<reset>

  Commands are prefixed by a forward-slash /.

  All Commands:
    <show_all_cmds>

<cyan>MudMaster Procedures:<reset>

  Procedures are special commands prefixed by the @ character and can be used
  in-line with Commands. Example: /chatall @AnsiReset()@ForeBlue()hello!
  will chat 'hello!' to all chat connections with the normal blue color.

  All Procedures:
    <show_all_procs>

]]
}

local function createAlignedColumnLinks(commands, columns, columnWidth, spacer)
  local result = ""
  local line = ""

  for i, command in ipairs(commands) do
      -- Create the link for the command
      local link = string.format("<link: %s>%s</link>", command, command)
  
      -- Add the link to the current line, ensuring it is padded to the column width
      line = line .. link .. string.rep(" ", columnWidth - #command) -- 15 for the length of "<link: ></link>"
   
      -- If this is the third column (assuming 3 columns per line), start a new line
      if i % columns == 0 then
          result = result .. line .. "\n" .. spacer
          line = ""
      end
  end

  -- Add any remaining commands if the number of commands is not a multiple of 3
  if line ~= "" then
      result = result .. line .. "\n"
  end

  return result
end



function MMCompat.debug(msg)
  if MMCompat.isDebug then
    echo("\n")
    cecho(string.format("<white>[<indian_red>MMCompat<orange>Debug<white>] %s", msg))
  end
end


function MMCompat.echo(msg)
  cecho(string.format("\n<white>[<indian_red>MMCompat<white>] %s", msg))
end


function MMCompat.error(msg)
  cecho(string.format("\n<white>[<indian_red>MMCompat <red>Error<white>] %s", msg))
end


function MMCompat.warning(msg)
  cecho(string.format("\n<white>[<indian_red>MMCompat <yellow>Warning<white>] %s", msg))
end


function MMCompat.initTopLevelGroup(group, type)
  if exists(group, type) == 0 then
    permGroup(group, type)
  end
end


-- Function to count the number of elements in a table
local function getTableLength(tbl)
  if not tbl then return 0 end
  local count = 0
  for _ in pairs(tbl) do
    count = count + 1
  end
  return count
end


function MMCompat.add_help(cmd, entry)
  if table.index_of(MMCompat.help, cmd) then
    return
  end

  MMCompat.helpEntries = MMCompat.helpEntries + 1

  local function add_help_cmd(cmd_str, cmd_entry)
    MMCompat.help[cmd_str] = cmd_entry

    if cmd_str:sub(1, 1) == '@' then
      MMCompat.helpProcs = MMCompat.helpProcs or {}
      table.insert(MMCompat.helpProcs, cmd_str)
    else
      MMCompat.helpCmds = MMCompat.helpCmds or {}
      table.insert(MMCompat.helpCmds, cmd_str)
    end
  end

  if type(cmd) == "table" then
    for k, v in pairs(cmd) do
      add_help_cmd(v, entry)
    end
  else
    add_help_cmd(cmd, entry)
  end

end


function MMCompat.add_command(cmd, cmdTbl)
  --cmdTable has help, pattern, func
  local funcTbl = {
    name = cmd,
    pattern = cmdTbl.pattern,
    cmd = cmdTbl.func
  }

  table.insert(MMCompat.functions, funcTbl)

  MMCompat.add_help(cmd, cmdTbl.help)
end


--[[
Help funcion, adapted from generic_mapper
]]
function MMCompat.show_help(cmd)

  if cmd and cmd ~= "" then
      local cmdLower = cmd:lower():gsub(" ","_")
      if not MMCompat.help[cmd] and not MMCompat.help[cmdLower] then
          MMCompat.echo("No help file on that command.")
          return
      end

      cecho("<yellow>"..cmd.."\n")
      cecho("<:RoyalBlue>                                                                                <reset>\n")
  else
      cmd = 1
  end

  for w in MMCompat.help[cmd]:gmatch("[^\n]*\n") do

    -- Special tag to show all commands with links
    if w:find("<show_all_cmds>") then
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
          if lineCount == 8 then
            echo("\n")
            lineCount = 0
          end
      end
      echo("\n")

    elseif w:find("<show_all_procs>") then
      -- Show all commands from MMCompat.helpProcs
      local sorted_procs = {}
      for _, help_cmd in pairs(MMCompat.helpProcs) do
          table.insert(sorted_procs, help_cmd)
      end

      table.sort(sorted_procs)

      local lineCount = 0
      for _, help_proc in pairs(sorted_procs) do
          cecho(" ")
          fg("yellow")
          setUnderline(true)
          echoLink(help_proc, [[MMCompat.show_help("]] .. help_proc .. [[")]], "View: " .. help_proc, true)
          setUnderline(false)
          resetFormat()
          lineCount = lineCount + 1
          if lineCount == 8 then
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

      -- handle multiple <url> and <link> tags on the same line
      local current_pos = 1
      local line_length = #w

      -- Pattern to match both opening <link:> and closing </link> tags
      local pattern = "(.-)<link: ([^>]+)>([^<]*)</link>"

      -- Iterate over all occurrences of the <link> pattern
      for before, link, linktext in w:gmatch(pattern) do
          -- Print the text before the link
          cecho(before)

          -- Set the link style
          fg("yellow")
          setUnderline(true)

          -- Create the link
          echoLink(linktext, [[MMCompat.show_help("]] .. link .. [[")]], "View: MMCompat help " .. link, true)

          -- Reset style
          setUnderline(false)
          resetFormat()

          -- Move the current position forward to the end of the last matched link
          current_pos = current_pos + #before + #link + #linktext + 15 -- 15 for the length of "<link: >" and "</link>"
      end

      -- Print the remaining part of the line (if any) after the last <link>
      if current_pos <= line_length then
          cecho(w:sub(current_pos))
      end

      --[=[
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
      --]=]
    end
  end

  cecho("<:RoyalBlue>                                                                                <reset>\n")

end


function MMCompat.restoreLocalEcho()
  if MMCompat.wasLocalEcho then
    setConfig("showSentText", true)
    MMCompat.isLocalEcho = true
  end
end


function MMCompat.disableLocalEcho()
  if MMCompat.isLocalEcho or getConfig("showSentText") then
    MMCompat.wasLocalEcho = true
    setConfig("showSentText", false)
    MMCompat.isLocalEcho = false
  end
end


function MMCompat.findActionTableIdx(tbl)
  for k, v in ipairs(MMCompat.save.actions) do
    -- Check if both 'name' and 'group' match the target table
    if v.pattern == tbl.pattern and v.cmd == tbl.cmd and v.group == tbl.group then
        return k
    end
  end
  return nil
end


function MMCompat.findAliasTableIdx(tbl)
  for k, v in ipairs(MMCompat.save.aliases) do
    -- Check if both 'name' and 'group' match the target table
    if v.name == tbl.name and v.group == tbl.group then
        return k
    end
  end
  return nil
end


function MMCompat.findArrayTableIdx(tbl)
  for k, v in ipairs(MMCompat.save.arrays) do
    -- Check if both 'name' and 'group' match the target table
    if v.name == tbl.name and v.group == tbl.group then
        return k
    end
  end
  return nil
end


function MMCompat.findEventTableIdx(tbl)
  for k, v in ipairs(MMCompat.save.events) do
    -- Check if both 'name' and 'group' match the target table
    if v.name == tbl.name and v.group == tbl.group then
        return k
    end
  end
  return nil
end


function MMCompat.findGagTableIdx(tbl)
  for k, v in ipairs(MMCompat.save.gags) do
    -- Check if both 'name' and 'group' match the target table
    if v.pattern == tbl.pattern and v.group == tbl.group then
        return k
    end
  end
  return nil
end


function MMCompat.findHighlightTableIdx(tbl)
  for k, v in ipairs(MMCompat.save.highlights) do
    -- Check if both 'name' and 'group' match the target table
    if v.pattern == tbl.pattern and v.group == tbl.group then
        return k
    end
  end
  return nil
end


function MMCompat.findListTableIdx(tbl)
  for k, v in ipairs(MMCompat.save.lists) do
    -- Check if both 'name' and 'group' match the target table
    if v.name == tbl.name and v.group == tbl.group then
        return k
    end
  end
  return nil
end


function MMCompat.findSubTableIdx(tbl)
  for k, v in ipairs(MMCompat.save.subs) do
    -- Check if both 'name' and 'group' match the target table
    if v.pattern == tbl.pattern and v.group == tbl.group then
        return k
    end
  end
  return nil
end


function MMCompat.findVariableTableIdx(tbl)
  for k, v in ipairs(MMCompat.save.variables) do
    -- Check if both 'name' and 'group' match the target table
    if v.name == tbl.name and v.group == tbl.group then
        return k
    end
  end
  return nil
end


-- function to find an action in MMCompat.save.actions by name or id
function MMCompat.findActionByNameOrId(name)
  local tbl = nil
  local idx = nil
  name = string.lower(name)

  local num = tonumber(name)
  if num then
      for k, v in pairs(MMCompat.save.actions) do
          if tonumber(k) == num then
              tbl = v
              idx = k
              break
          end
      end

      if not tbl then
          MMCompat.warning("Unable to find action with id ".. num)
          return
      end
  else
      for k, v in pairs(MMCompat.save.actions) do
          if string.lower(v.pattern) == name then
              tbl = v
              idx = k
              break
          end
      end

      if not tbl then
          MMCompat.warning("Unable to find action with pattern '".. name.."'")
          return
      end
  end

  return tbl, idx
end


-- function to find an alias in MMCompat.save.aliases by name or id
function MMCompat.findAliasByNameOrId(name)
  local tbl = nil
  name = string.lower(name)

  local idx = nil
  local num = tonumber(name)
  if num then
      for k, v in pairs(MMCompat.save.aliases) do
          if tonumber(k) == num then
              tbl = v
              idx = k
              break
          end
      end

      if not tbl then
          MMCompat.warning("Unable to find alias with id ".. num)
          return
      end
  else
      for k, v in pairs(MMCompat.save.aliases) do
          if string.lower(v.pattern) == name then
              tbl = v
              idx = k
              break
          end
      end

      if not tbl then
          MMCompat.warning("Unable to find alias with pattern '".. name.."'")
          return
      end
  end

  return tbl, idx
end


-- function to find a list in MMCompat.save.lists by name or id
function MMCompat.findListByNameOrId(listName)
  local listTbl = nil
  local idx = nil
  local listNum = tonumber(listName)
  if listNum then
      for k, v in pairs(MMCompat.save.lists) do
          if tonumber(k) == listNum then
              listTbl = v
              idx = k
              break
          end
      end

      if not listTbl then
          MMCompat.warning("Unable to find list with id ".. listNum)
          return
      end
  else
      for k, v in pairs(MMCompat.save.lists) do
          if string.lower(v.name) == listName then
              listTbl = v
              idx = k
              break
          end
      end

      if not listTbl then
          MMCompat.warning("Unable to find list with name '".. listName.."'")
          return
      end
  end

  return listTbl, idx
end


function MMCompat.pop_undo()
  if MMCompat.save.undoStack and #MMCompat.save.undoStack > 0 then
    local cmdTbl = MMCompat.save.undoStack[#MMCompat.save.undoStack]
    table.remove(MMCompat.save.undoStack, 1)
    return cmdTbl
  end
end


function MMCompat.push_undo(cmdTbl, cmdType)
  cmdTbl.type = cmdType
  table.insert(MMCompat.save.undoStack, cmdTbl)

  local numItems = #MMCompat.save.undoStack

  if numItems == 51 then
    table.remove(MMCompat.save.undoStack, 1)
  end
end


function MMCompat.parseCommaValues(str)
    local val1 = nil
    local val2 = nil

    for v1, v2 in str:gmatch("(%d+)%s*,?%s*(%d*)") do
        val1 = tonumber(v1)
        if v2 ~= "" then
            val2 = tonumber(v2)
        end
        return val1, val2
    end

    return nil, nil
end


function MMCompat.convertColorToRGB(mm_color, default_color)

  if mm_color and mm_color ~= "" then
    mm_color = string.gsub(mm_color, "%s", "_")
  end

  local rgb_color = color_table[mm_color]

  if not rgb_color then
    MMCompat.warning("Color " .. mm_color .. " not found in Mudlet color table, using '"..default_color.."'")
    return color_table[default_color]
  end

  return rgb_color
end


-- Function to replace %1, %2, etc., with named regex captures in the patterns
-- of triggers and aliases
function MMCompat.parseCaptures(pattern)
  local result = ""
  local anyCaptures = false

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
        anyCaptures = true
      else
        -- no digits follow %, just add the % to the result
        result = result .. c
        i = i + 1
      end

    else
      -- Regular character, just add it to the result
      result = result .. c
      i = i + 1
    end
  end

  return result, anyCaptures
end


--[[
  Ported code from MudMaster2k source
]]
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

  -- need to handle parentheses without them being a procedure
  -- as well as quotes for strings

  while ptrInc <= #strText do
      local ch = strText:sub(ptrInc, ptrInc)
      ch1 = strText:sub(ptrInc + 1, ptrInc + 1)
      --MMCompat.debug(string.format("findStatement ch '%s'  ch1 '%s'", ch, ch1))

      -- Handle escape sequences for procedure characters
      if ch == chEscape and ch1 == procChar then
          -- 1
          table.insert(buffer, chEscape)
          table.insert(buffer, procChar)
          ptrInc = ptrInc + 2
      elseif ch == procChar then
          -- 2
          -- Need to watch for procedures.  Each time we find a procedure
		      -- we need to look for a matched set of parens.
          nPotentialProcCount = nPotentialProcCount + 1
          table.insert(buffer, ch)
          ptrInc = ptrInc + 1
      elseif ch == '(' and nPotentialProcCount > 0 then
          -- 3
          -- if we've seen an @ and now a ( it is a procedure
          nProcCount = nProcCount + 1
          nPotentialProcCount = nPotentialProcCount - 1
          table.insert(buffer, ch)
          ptrInc = ptrInc + 1
      elseif ch == chEscape and ch1 == ')' then
          -- 4
          -- If the user wants to print a closing paren while inside
          -- a procedure definition, they need to use the escape char.
          --table.insert(buffer, chEscape)
          table.insert(buffer, ')')
          --MMCompat.debug("findStatement (4) buffer: '"..buffer.."'")
          ptrInc = ptrInc + 2
      elseif ch == ')' and nProcCount > 0 then
          -- 5
          -- Decrement procedure count for closing parentheses
          nProcCount = nProcCount - 1
          table.insert(buffer, ch)
          --MMCompat.debug("findStatement (5) buffer: '"..buffer.."'")
          ptrInc = ptrInc + 1
      elseif ch == chEndChar and nProcCount == 0 then
          -- 6
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
          -- 7
          -- If this is the first block symbol we need to skip over it, it should not
		      -- be part of our result string.
          nBlockCount = nBlockCount + 1
          ptrInc = ptrInc + 1
      elseif ch == chStartChar and nProcCount == 0 then
          -- 8
          -- Nested blocks
          nBlockCount = nBlockCount + 1
          table.insert(buffer, ch)
          ptrInc = ptrInc + 1
      else
          -- 9
          -- Add the character to the buffer
          table.insert(buffer, ch)
          --MMCompat.debug("findStatement (9) buffer: '"..buffer.."'")
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

  --local processedStr = MMCompat.replaceProcedureCalls(str)

  return str, anyMatch
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
  --local processedStr = MMCompat.replaceProcedureCalls(str)

  return str, anyMatch
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
  --if MMCompat.isDebug then
  --  display(matches)
  --  echo("\n")
  --end

  for k, v in pairs(matches) do
    --MMCompat.debug(string.format("assigning key: %s  value: %s", k, v))
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

      local cmd = v
  
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
      matchStr = [[MMCompat.templateAssignGlobalMatches() MMCompat.disableLocalEcho()]]
      matchStr = matchStr .. "\n"
  end

  return matchStr .. expandedStr .. "\nMMCompat.restoreLocalEcho()"
end


local function findProcedure(name)
  for _, proc in ipairs(MMCompat.procedures) do
      if proc.name == name then
          if not proc.cmd then
            MMCompat.warning("No command defined for procedure '"..proc.name.."'")
          end
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
  --MMCompat.debug("replaceProcedureCalls: " .. text)

  -- Pattern to find calls like @ProcedureName(arg1, arg2, ...)
  local pattern = "@(%w+)%((.+)%)"

  -- Function to process each match
  local function processProcCall2(procedure_name, arguments)
    MMCompat.debug(string.format("processProcCall: %s args: %s",
                  procedure_name, arguments))

      -- Find the function by procedure name
      local procedure = findProcedure(procedure_name)
      if procedure then
          -- Split arguments by comma and trim spaces
          local args = {}
          for arg in arguments:gmatch("[^,]+") do
            MMCompat.debug("parseArgument("..arg..")")
            local strFunc = parseArgument(arg)
            MMCompat.debug("processProcCall strFunc: " .. strFunc)
            table.insert(args, strFunc)
          end
          -- Call the procedure with the parsed arguments
          local result = procedure(unpack(args))

          return tostring(result)
      else
          MMCompat.debug("procedure not found")
          -- If the procedure is not found, return the original text
          return "@" .. procedure_name .. "(" .. arguments .. ")"
      end
  end

  local function processProcCall(procedure_name, arguments)
    MMCompat.debug(string.format("processProcCall: %s args: '%s'", procedure_name, arguments))

    -- Find the function by procedure name
    local procedure = findProcedure(procedure_name)
    if procedure then
        -- Split arguments by commas but account for escaped characters like "\,"
        local args = {}
        local current_arg = ""
        local in_escape = false

        for i = 1, #arguments do
          local char = arguments:sub(i, i)

          if in_escape then
            current_arg = current_arg .. char
            in_escape = false
          elseif char == "\\" then
            in_escape = true
          elseif char == "," then
            table.insert(args, current_arg:match("^%s*(.-)%s*$")) -- trim spaces
            current_arg = ""
          else
            current_arg = current_arg .. char
          end
        end

        -- Add the final argument
        if current_arg ~= "" then
          table.insert(args, current_arg:match("^%s*(.-)%s*$")) -- trim spaces
        end

        -- Call the procedure with the parsed arguments
        local result = procedure(unpack(args))

        return tostring(result)
    else
        MMCompat.debug("procedure not found")
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
      MMCompat.debug("Creating group " .. itemType .. "/" .. group.."\n")
      permGroup(group, itemType, itemParent)
      return group
    else
      -- Group already exists, return the itemParent without creating new group
      MMCompat.debug("Group " .. itemType .. "/" .. group .." exists\n")
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
  local arrayTbl = nil
  for k, v in pairs(MMCompat.save.arrays) do
      if v.name == name then
         
          -- check bounds
          if row > v.bounds.rows then
              MMCompat.error(string.format("Array '%s' row index out of bounds, given %d, bounds %d",
                  v.name, row, v.bounds.row))
              return nil
          end

          if v.bounds.cols and col and col > v.bounds.cols then
              MMCompat.error(string.format("Array '%s' col index out of bounds, given %d, bounds %d",
                  v.name, col, v.bounds.col))
              return nil
          end

          arrayTbl = v

          break
      end
  end

  return arrayTbl
end


function MMCompat.listActions()
  echo("# Defined Actions:\n")
  for k, v in ipairs(MMCompat.save.actions) do
    local statusChr = ' '
    if not v.enabled then
      statusChr = '*'
    end
    cecho(string.format("<white>%03d:<reset>%s{%s} {%s} {%s}\n",
        tonumber(k), statusChr, v.pattern, v.cmd, v.group))
  end
end


function MMCompat.listAliases()
  echo("# Defined Aliases:\n")
  for k, v in ipairs(MMCompat.save.aliases) do
    local statusChr = ' '
    if not v.enabled then
      statusChr = '*'
    end
    cecho(string.format("<white>%03d:<reset>%s{%s} {%s} {%s}\n",
        tonumber(k), statusChr, v.pattern, v.commands, v.group))
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


function MMCompat.listVariables()
  echo("# Defined Variables:\n")
  for k, v in ipairs(MMCompat.save.variables) do

    local varValue = MMGlobals[v.name] or ""

    cecho(string.format("<white>%03d:<reset>{%s} {%s} {%s}\n",
        tonumber(k), v.name, varValue, v.group))
  end
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
      {name="A",              cmd=function(name, row, col) return MMCompat.procGetArray(name, row, col) end},
      {name="Abs",            cmd=function(val) return math.abs(val) end},
      {name="AnsiBold",       cmd=function() return MMCompat.ansiBold end},
      {name="AnsiReset",      cmd=function() return MMCompat.ansiReset end},
      {name="AnsiRev",        cmd=function() return MMCompat.ansiReverse end},
      {name="AnsiReverse",    cmd=function() return MMCompat.ansiReverse end},
      {name="Arr",            cmd=function(name, row, col) return MMCompat.procGetArray(name, row, col) end},
      {name="Asc",            cmd=function(chr) return MMCompat.procAsc(chr) end},
      {name="BackBlack",      cmd=function(val) return MMCompat.backColorTable[8] end},
      {name="BackBlue",       cmd=function(val) return MMCompat.backColorTable[1] end},
      {name="BackColor",      cmd=function(num) return MMCompat.procBackColor(num) end},
      {name="BackCyan",       cmd=function() return MMCompat.backColorTable[3] end},
      {name="BackGreen",      cmd=function() return MMCompat.backColorTable[2] end},
      {name="BackMagenta",    cmd=function() return MMCompat.backColorTable[5] end},
      {name="BackRed",        cmd=function() return MMCompat.backColorTable[4] end},
      {name="BackYellow",     cmd=function() return MMCompat.backColorTable[6] end},
      {name="Backward",       cmd=function(str) return str:reverse() end},
      {name="BackWhite",      cmd=function() return MMCompat.backColorTable[7] end},
      -- TODO
      {name="CharColor",      cmd=MMCompat.procCharColor},
      {name="Chr",            cmd=function(val) return string.char(val) end},
      {name="Commma",         cmd=function(str) return MMCompat.procComma(str) end},
      {name="CommandToList",  cmd=MMCompat.procCmdToList},
      {name="ConCat",         cmd=function(a, b) return a..b end},
      {name="Connected",      cmd=function() return MMCompat.procConnected() end},
      {name="Day",            cmd=function() return MMCompat.procDay() end},
      {name="DeComma",        cmd=function(str) return MMCompat.procDeComma(str) end},
      {name="Enum",           cmd=function(list, item) return MMCompat.procEnum(list, item) end},
      {name="EnumList",       cmd=function(list, item) return MMCompat.procEnum(list, item) end},
      {name="EventTime",      cmd=function(name) return MMCompat.procEventTime(name) end},
      {name="Exists",         cmd=function(name) return MMCompat.procExists(name) end},
      {name="FileExists",     cmd=function(name) return MMCompat.procFileExists(name) end},
      {name="ForeBlack",      cmd=function() return MMCompat.foreColorTable[8] end},
      {name="ForeBlue",       cmd=function() return MMCompat.foreColorTable[1] end},
      {name="ForeColor",      cmd=function(num) return MMCompat.procForeColor(num) end},
      {name="ForeCyan",       cmd=function() return MMCompat.foreColorTable[3] end},
      {name="ForeGreen",      cmd=function() return MMCompat.foreColorTable[2] end},
      {name="ForeMagenta",    cmd=function() return MMCompat.foreColorTable[5] end},
      {name="ForeRed",        cmd=function() return MMCompat.foreColorTable[4] end},
      {name="ForeYellow",     cmd=function() return MMCompat.foreColorTable[6] end},
      {name="ForeWhite",      cmd=function() return MMCompat.foreColorTable[7] end},
      {name="GetArray",       cmd=function(name, row, col) return MMCompat.procGetArray(name, row, col) end},
      {name="GetArrayRows",   cmd=function(name) return MMCompat.procGetArrayRows(name) end},
      {name="GetArrayCols",   cmd=function(name) return MMCompat.procGetArrayCols(name) end},
      {name="GetCount",       cmd=function(name) return MMCompat.procGetCount(name) end},
      {name="GetItem",        cmd=function(name, num) return MMCompat.procGetItem(name, num) end},
      {name="Hour",           cmd=function() return os.date("%H") end},
      {name="If",             cmd=function(cond) return MMCompat.procIf(cond) end},
      {name="InList",         cmd=function(name, item) return MMCompat.procInList(name, item) end},
      {name="IsNumber",       cmd=function(val) return tonumber(val ~= nil) end},
      {name="IsEmpty",        cmd=function(var) return MMCompat.procIsEmpty(var) end},
      {name="IP",             cmd=function() return "127.0.0.1" end},
      {name="Left",           cmd=function(val, n) return string.sub(val, 1, n) end},
      {name="LeftPad",        cmd=function(str, char, n) return string.rep(char, n) .. str end},
      {name="Len",            cmd=function(str) return string.len(str) end},
      {name="Lower",          cmd=function(val) return string.lower(val) end},
      {name="LTrim",          cmd=function(val) return val:match("^%s*(.-)$") end},
      {name="Math",           cmd=function(str) return MMCompat.procMath(str) end},
      {name="Microsecond",    cmd=function() return MMCompat.procMicrosecond() end},
      {name="Mid",            cmd=function(str, start, n) return string.sub(str, start, start + n - 1) end},
      {name="Minute",         cmd=function() return os.date("%M") end},
      {name="Month",          cmd=function() return os.date("%B") end},
      {name="NumActions",     cmd=function() return getTableLength(MMCompat.save.actions) end},
      {name="NumAliases",     cmd=function() return getTableLength(MMCompat.save.aliases) end},
      {name="NumBarItems",    cmd=MMCompat.procNumBarItems},
      {name="NumEvents",      cmd=function() return getTableLength(MMCompat.save.events) end},
      {name="NumGags",        cmd=function() return getTableLength(MMCompat.save.gags) end},
      {name="NumHighlights",  cmd=function() return getTableLength(MMCompat.save.highlights) end},
      {name="NumLists",       cmd=function() return getTableLength(MMCompat.save.lists) end},
      {name="NumMacros",      cmd=function() return getProfileStats().keys.active end},
      {name="NumTabList",     cmd=MMCompat.procNumTabList},
      {name="NumVariables",   cmd=function() return getTableLength(MMCompat.save.variables) end},
      {name="PadLeft",        cmd=function(str, char, n) return string.rep(char, n) .. str end},
      {name="PadRight",       cmd=function(str, char, n) return str .. string.rep(char, n) end},
      {name="PreTrans",       cmd=function(val) return MMCompat.referenceVariables(val) end},
      {name="ProcedureCount", cmd=function() return #MMCompat.procedures end},
      {name="Random",         cmd=function(val) return math.random(1, val) end},
      {name="Regex",          cmd=function(regex, str) return MMCompat.procRegex(regex, str) end},
      {name="RegexMatch",     cmd=function(regex, str) return MMCompat.procRegexMatch(regex, str) end},
      {name="Replace",        cmd=function(str, strF, strR) return MMCompat.procReplace(str, strF, strR) end},
      {name="Right",          cmd=function(val, n) return string.sub(val, -n) end},
      {name="RightPad",       cmd=function(str, char, n) return str .. string.rep(char, n) end},
      {name="RTrim",          cmd=function(val) return val:match("^(.-)%s*$") end},
      {name="Second",         cmd=function() return os.date("%S") end},
      {name="SessionName",    cmd=function() return getProfileName() end},
      {name="SessionPath",    cmd=function() return getMudletHomeDir() end},
      {name="StripAnsi",      cmd=function(str) return MMCompat.procStripAnsi(str) end},
      {name="StrStr",         cmd=function(str, search) return MMCompat.procStrStr(str, search) end},
      {name="StrStrRev",      cmd=function(str, search) return MMCompat.procStrStrRev(str, search) end},
      {name="SubStr",         cmd=function(str, sIdx, eIdx) return MMCompat.procSubStr(str, sIdx, eIdx) end},
      {name="Time",           cmd=function() return MMCompat.procTime() end},
      {name="TimeToDay",      cmd=function(t) return MMCompat.procTimeToDay(t) end},
      {name="TimeToDayOfWeek",cmd=function(t) return MMCompat.procTimeToDayOfWeek(t) end},
      {name="TimeToHour",     cmd=function(t) return MMCompat.procTimeToHour(t) end},
      {name="TimeToMinute",   cmd=function(t) return MMCompat.procTimeToMinute(t) end},
      {name="TimeToMonth",    cmd=function(t) return MMCompat.procTimeToMonth(t) end},
      {name="TimeToSecond",   cmd=function(t) return MMCompat.procTimeToSecond(t) end},
      {name="TimeToYear",     cmd=function(t) return MMCompat.procTimeToYear(t) end},
      {name="TextColor",      cmd=function(str) return MMCompat.procTextColor(str) end},
      {name="Upper",          cmd=function(str) return MMCompat.procUpper(str) end},
      {name="Var",            cmd=function(var) return MMCompat.procVar(var) end},
      {name="Version",        cmd=function() return "MMCompat " .. MMCompat.version end},
      {name="Word",           cmd=function(str, num) return MMCompat.procWord(str, num) end},
      {name="WordColor",      cmd=function(num) return MMCompat.procWordColor(num) end},
      {name="WordCount",      cmd=function(str) return MMCompat.procWordCount(str) end},
      {name="Year",           cmd=function() return os.date("%Y") end}
    }

    MMCompat.loadData()

    tempTimer(.25, [[MMCompat.display_info()]])

end


function MMCompat.display_info()
  -- yea this probably doesnt belong here, move later
  for _,v in pairs(MMCompat.functions) do
    local aliasId = tempAlias(v.pattern, v.cmd)
    cecho(string.format("\n<white>[<indian_red>MMCompat<white>] Loaded <LawnGreen>%s <white>command, id: <green>%d", v.name, aliasId))
    table.insert(MMCompat.scriptAliases, aliasId)
  end

  MMCompat.echo(string.format("MudMaster Compatibility v <yellow>%s <white>loaded...", MMCompat.version))
  MMCompat.echo(string.format("    <green>%d <white>commands, <green>%d <white>procedures, <green>%d <white>help entries",
    #MMCompat.functions, #MMCompat.procedures, MMCompat.helpEntries))
  MMCompat.echo(string.format("    <yellow>%d <white>actions, <yellow>%d <white>aliases, <yellow>%d <white>events, <yellow>%d <white>arrays, <yellow>%d <white>lists, <yellow>%d <white>variables",
    getTableLength(MMCompat.save.actions),
    getTableLength(MMCompat.save.aliases),
    getTableLength(MMCompat.save.events),
    getTableLength(MMCompat.save.arrays),
    getTableLength(MMCompat.save.lists),
    getTableLength(MMCompat.save.variables)))
  MMCompat.echo("Type /help for the MudMaster help system")

  if getCommandSeparator() == ';' then
    MMCompat.warning("You have defined your Mudlet command separator as a single semicolon")
    MMCompat.warning("This will interfere with the functionality of MMCompat!")
  end
end


function MMCompat.saveData()
  if MMCompat.isLoading then
    return
  end

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
  MMCompat.save.aliases = MMCompat.save.aliases or {}
  MMCompat.save.arrays = MMCompat.save.arrays or {}
  MMCompat.save.events = MMCompat.save.events or {}
  MMCompat.save.lists = MMCompat.save.lists or {}
  MMCompat.save.macros = MMCompat.save.macros or {}
  MMCompat.save.gags = MMCompat.save.gags or {}
  MMCompat.save.highlights = MMCompat.save.highlights or {}
  MMCompat.save.subs = MMCompat.save.subs or {}
  MMCompat.save.variabes = MMCompat.save.variables or {}
  MMCompat.save.undoStack = MMCompat.save.undoStack or {}

  MMCompat.echo("Loaded MudMaster script data for <yellow>" .. charName)
end

if not MMCompat.isInitialized then
  math.randomseed(os.time())
  MMCompat.config()
end

if MMCompat.helpAliasId then
  killAlias(MMCompat.helpAliasId)
end

MMCompat.helpAliasId = tempAlias([[^/help(?: (.*))?]], [[MMCompat.show_help(matches[2])]])

MMCompat.initTopLevelGroup("MMAliases", "alias")
MMCompat.initTopLevelGroup("MMEvents", "timer")
MMCompat.initTopLevelGroup("MMActions", "trigger")
MMCompat.initTopLevelGroup("MMGags", "trigger")
MMCompat.initTopLevelGroup("MMHighlights", "trigger")
MMCompat.initTopLevelGroup("MMSubstitutions", "trigger")

MMCompat.add_help('commands', [[
  <cyan>Chat Commands<reset>
  ]]
    ..createAlignedColumnLinks({'call', 'chat', 'chatall',
                                'chatname', 'emote', 'emoteall', 'unchat'}, 3, 20, "  ")..
  [[

  <cyan>List Commands<reset>
  ]]
    ..createAlignedColumnLinks({'clearlist', 'itemadd', 'itemdelete',
                                'listadd', 'listcopy', 'listdelete',
                                'listitems', 'lists'}, 3, 20, "  ")..
  [[

  <cyan>Script Control Commands<reset>
  ]]
    ..createAlignedColumnLinks({'disableaction', 'disablealias', 'disableevent', 'disablegroup', 'editaction', 'editalias', 'editvariable',
                                'enableaction', 'enablealias', 'enablegroup', 'killgroup', 'resetevent',
                                'seteventtime', 'unaction', 'unalias', 'unarray',
                                'unevent', 'unvariable'}, 3, 20, "  ")..
  [[

  <cyan>Dll Commands<reset>
  ]]
    ..createAlignedColumnLinks({'calldll', 'dll', 'freelibrary', 'loadlibrary'}, 3, 20, "  ")..
  [[

  <cyan>Script Entity Information<reset>

  <cyan>Sound Commands<reset>

  <cyan>Script Entities<reset>
  ]]
    ..createAlignedColumnLinks({'action', 'alias', 'array',
                                'assign', 'empty', 'event',
                                'gag', 'highlight', 'macro',
                                'substitute', 'variable'}, 3, 20, "  ")..
  [[

  <cyan>Log Commands<reset>

  <cyan>Script Flow Control<reset>
  ]]
    ..createAlignedColumnLinks({'if', 'loop', 'while'}, 3, 20, "  ")..
  [[

  <cyan>Session Control Commands<reset>
  <link: zap>zap</link>

  <cyan>Display Output Commands<reset>
  ]]
  ..createAlignedColumnLinks({'cr', 'showme'}, 3, 20, "  ")..
  [[

  <cyan>Speed Walk Commands<reset>

  <cyan>File Commands<reset>
  <link: read>read</link>

  <cyan>Session Window Commands<reset>

  <cyan>Other<reset>
  ]]
    ..createAlignedColumnLinks({'clearscreen', 'math', 'remark'}, 3, 20, "  ")..
  [[

]])

MMCompat.isInitialized = true