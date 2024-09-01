MMCompatTest = {}

function MMCompatTest.echo(msg)
    cecho(string.format("\n<white>[<indian_red>MMCompatTest<white>] %s", msg))
end


function MMCompatTest.testPassFailResult(testName, resultTbl)
    if MMCompat.isDebug then
        display(resultTbl)
    end

    if resultTbl.expected == resultTbl.actual then
        MMCompatTest.echo(testName .. " PASSED")
        resultTbl.passCount = resultTbl.passCount + 1
    else
        MMCompatTest.echo(string.format(testName .." FAILED, expected: '%s' actual: '%s'",
            resultTbl.expected, resultTbl.actual))
        resultTbl.failCount = resultTbl.failCount + 1
    end
end


function MMCompatTest.passFailReport(testName, resultTbl)
    local totalTests = resultTbl.passCount + resultTbl.failCount
    if resultTbl.failCount > 0 then
        MMCompatTest.echo(string.format("%s <red>FAILED<white>, <green>%d<white>/<yellow>%d <white>passed, <red>%d<white>/<yellow>%d <white>failed",
            testName, resultTbl.passCount, totalTests, resultTbl.failCount, totalTests))
    else
        MMCompatTest.echo(string.format("%s <green>PASSED %d<white>/<yellow>%d <white>tests",
            testName, resultTbl.passCount, totalTests))
    end
end


function MMCompatTest.testOutputTemplate(typeName, funcName, groupName, setupFunc, testFunc, expectedResult)
    local outputName = funcName .. "Output"

    MMCompatTest.echo("Creating "..typeName.."...")
    setupFunc(funcName, expectedResult)
    MMCompatTest.echo("    Done creating "..typeName)

    if exists(funcName.." %1", groupName) == 0 then
        MMCompatTest.echo(funcName .. " <red>FAILED<white>, no "..typeName.." created")
        return
    end

    MMCompatTest.resultTbl = {
        expected = expectedResult,
        actual = "<unset>",
        passCount = 0,
        failCount = 0,
    }

    MMCompatTest.echo("Creating tempTrigger")
    local trigId = tempRegexTrigger("^"..outputName.." (.*)",
        function()
            if MMCompat.isDebug then
                echo("\n<<Outputing "..funcName..">>\n")
                display(matches)
                display(MMCompatTest.resultTbl)
            end
            MMCompatTest.resultTbl.actual = matches[2]
            MMCompatTest.testPassFailResult(funcName, MMCompatTest.resultTbl)
        end
    , 1)
    MMCompatTest.echo("    Done Creating tempTrigger, id: " .. trigId)
    
    MMCompatTest.echo("Testing "..typeName.."...")
    testFunc(funcName, expectedResult)
    MMCompatTest.echo("    Done testing "..typeName)

    killTrigger(trigId)

    MMCompatTest.passFailReport(funcName, MMCompatTest.resultTbl)
end


function MMCompatTest.testScriptTemplate(funcName, setupFunc, testFunc, expectedResult)
    local outputName = funcName .. "Output"

    --MMCompatTest.echo("Creating "..typeName.."...")
    local newExpected = setupFunc(funcName, expectedResult)
    --MMCompatTest.echo("    Done creating "..typeName)

    MMCompatTest.resultTbl = {
        expected = newExpected,
        actual = "<unset>",
        passCount = 0,
        failCount = 0,
    }
    
    --MMCompatTest.echo("Testing "..typeName.."...")
    local funcRet, funcValRet = testFunc(funcName, newExpected)
    --MMCompatTest.echo("    Done testing "..typeName)

    MMCompatTest.resultTbl.actual = funcValRet
    MMCompatTest.testPassFailResult(funcName, MMCompatTest.resultTbl)

    MMCompatTest.passFailReport(funcName, MMCompatTest.resultTbl)
end

--[[
function MMCompatTest.testAction1()
    MMCompatTest.echo("Creating action...")
    expandAlias("/action {actionTest1 %1} {/showme actionTest1Output $1}")
    MMCompatTest.echo("    Done creating action")

    if exists("actionTest1 %1", "MMActions") == 0 then
        MMCompatTest.echo("actionTest1 FAILED, no action created")
        return
    end

    MMCompatTest.resultTbl = {
        expected = "test123",
        actual = "<unset>",
        passCount = 0,
        failCount = 0,
    }

    MMCompatTest.echo("Creating tempTrigger")
    local trigId = tempRegexTrigger("^actionTest1Output (.*)",
        function()
            if MMCompat.isDebug then
                echo("\n<<Outputing testAction1>>\n")
                display(matches)
                display(MMCompatTest.resultTbl)
            end
            MMCompatTest.resultTbl.actual = matches[2]
            MMCompatTest.testPassFailResult("testAction1", MMCompatTest.resultTbl)
        end
    , 1)
    MMCompatTest.echo("    Done Creating tempTrigger, id: " .. trigId)
    
    MMCompatTest.echo("Testing action...")
    expandAlias("/showme actionTest1Output " .. MMCompatTest.resultTbl.expected)
    MMCompatTest.echo("    Done testing action")

    killTrigger(trigId)

    MMCompatTest.passFailReport("testAction1", MMCompatTest.resultTbl)
end
]]

--[[
function MMCompatTest.testAlias1()
    MMCompatTest.echo("Creating alias...")
    expandAlias("/alias {aliasTest1 %1} {/showme aliasTest1Output $1}")
    MMCompatTest.echo("    Done creating alias")

    if exists("aliasTest1 %1", "MMAliases") == 0 then
        MMCompatTest.echo("aliasTest1 FAILED, no alias created")
        return
    end

    MMCompatTest.resultTbl = {
        expected = "test123",
        actual = "<unset>",
        passCount = 0,
        failCount = 0,
    }

    MMCompatTest.echo("Creating tempTrigger")
    local trigId = tempRegexTrigger("^aliasTest1Output (.*)",
        function()
            if MMCompat.isDebug then
                echo("\n<<Outputing testAlias1>>\n")
                display(matches)
                display(MMCompatTest.resultTbl)
            end
            MMCompatTest.resultTbl.actual = matches[2]
            MMCompatTest.testPassFailResult("testAlias1", MMCompatTest.resultTbl)
        end
    , 1)
    MMCompatTest.echo("    Done Creating tempTrigger, id: " .. trigId)
    
    MMCompatTest.echo("Testing alias...")
    expandAlias("/aliasTest1 " .. MMCompatTest.resultTbl.expected)
    MMCompatTest.echo("    Done testing alias")

    killTrigger(trigId)

    MMCompatTest.passFailReport("testAlias1", MMCompatTest.resultTbl)
end
]]

--[[
function MMCompatTest.testAlias2()
    MMCompatTest.echo("Creating alias...")
    expandAlias("/alias {aliasTest2} {/if {$testAlias2 == 1} {/showme thenCondition $testAlias2} {/showme elseCondition $testAlias2}}")
    MMCompatTest.echo("    Done creating alias")

    if exists("aliasTest2 %1", "MMAliases") == 0 then
        MMCompatTest.echo("aliasTest2 FAILED, no alias created")
        return
    end

    MMCompatTest.resultTbl = {
        expected = "1",
        actual = "<unset>",
        passCount = 0,
        failCount = 0,
    }

    MMCompatTest.echo("Creating tempTrigger for THEN condition")
    local trigId = tempRegexTrigger("^thenCondition (\\d+)",
        function()
            MMCompatTest.resultTbl.actual = matches[2]
            MMCompatTest.testPassFailResult("testAlias2", MMCompatTest.resultTbl)
        end
    , 1)
    MMCompatTest.echo("    Done Creating tempTrigger for THEN condition, id: " .. trigId)

    MMCompatTest.echo("Testing alias THEN condition...")
    MMGlobals = MMGlobals or {}
    MMGlobals.testAlias2 = 1
    expandAlias("/aliasTest2 ".. MMGlobals.testAlias2)
    MMCompatTest.echo("    Done testing alias THEN condition")

    killTrigger(trigId)

    MMCompatTest.resultTbl.expected = "0"
    MMCompatTest.resultTbl.actual = "<unset>"

    MMCompatTest.echo("Creating tempTrigger for ELSE condition")
    trigId = tempRegexTrigger("^elseCondition (\\d+)",
        function()
            MMCompatTest.resultTbl.actual = matches[2]
            MMCompatTest.testPassFailResult("testAlias2", MMCompatTest.resultTbl)
        end
    , 1)
    MMCompatTest.echo("    Done Creating tempTrigger for ELSE condition, id: " .. trigId)

    MMCompatTest.echo("Testing alias ELSE condition...")
    MMGlobals.testAlias2 = 0
    expandAlias("/aliasTest2 " .. MMGlobals.testAlias2)
    MMCompatTest.echo("    Done testing alias ELSE condition")

    killTrigger(trigId)

    MMCompatTest.passFailReport("testAlias2", MMCompatTest.resultTbl)
end
]]

MMCompatTest.scriptAliases = MMCompatTest.scriptAliases or {}

for _,v in ipairs(MMCompatTest.scriptAliases) do
    killAlias(v)
end

MMCompatTest.scriptAliases = {}

MMCompatTest.functions = {
    { 
        name = "testAction1",
        template = "output",
        typeName = "trigger",
        groupName = "MMActions",
        pattern = [[^testAction1$]],
        expected = "test123",
        setupFunc = function(funcName, outputValStr)
            -- Set up action to look for 'testAction1 test123' to '/showme testAction1Output test123'
            expandAlias("/action {"..funcName.." %1} {/showme "..funcName.."Output $1}")
        end,
        testFunc = function(funcName, outputValStr)
            -- Now trigger the action with /showme testAction1 test123
            expandAlias("/showme "..funcName.." " .. MMCompatTest.resultTbl.expected)
        end
    },
    {
        name = "testAction2",
        template = "output",
        typeName = "trigger",
        groupName = "MMActions",
        pattern = [[^testAction2$]],
        expected = "test456",
        setupFunc = function(funcName, outputValStr)
            -- Set up action to look for 'testAction2 <something>', with an if condition
            -- that tests if <something> == test456 then sets MMGlobals['testAction2'] to 1, else 0
            local evtCode = string.format("/action {%s %s} {/if {$1 == %s} {/variable %s 1} {/variable %s 0}}",
                funcName, "%1", outputValStr, funcName, funcName)
            if MMCompat.isDebug then
                display(MMGlobals)
            end
            expandAlias(evtCode)
        end,
        testFunc = function(funcName, outputValStr)
            -- This will trigger the action created in setupFunc and set MMGlobals['testAction2'] to 1
            -- by outputting testAction2 test456
            MMGlobals[funcName] = "<unset>"

            local actionCode = string.format("\n%s %s\n", funcName, outputValStr)

            if MMCompat.isDebug then
                display(MMGlobals)
            end
            echo("actionCode: " .. actionCode .. "\n")
            feedTriggers(actionCode)
        end
    },
    {
        name = "testAlias1",
        template = "output",
        typeName = "alias",
        groupName = "MMAliases",
        pattern = [[^testAlias1$]],
        expected = "test123",
        setupFunc = function(funcName, outputValStr)
            expandAlias("/alias {"..funcName.." %1} {/showme "..outputValStr.." $1}")
        end,
        testFunc = function(funcName, outputValStr)
            expandAlias("/"..funcName.." " .. MMCompatTest.resultTbl.expected)
        end
    },
    {
        name = "testAlias2",
        template = "output",
        typeName = "alias",
        groupName = "MMAliases",
        pattern = [[^testAlias2$]],
        expected = "1",
        setupFunc = function(funcName, outputValStr)
            MMGlobals[funcName] = 1
            expandAlias("/alias {"..funcName.."} {/if {$"..funcName.." == 1} {/showme "..outputValStr.." 1} {/showme "..outputValStr.." 0}}")
        end,
        testFunc = function(funcName, outputValStr)
            expandAlias("/"..funcName.." " .. MMGlobals.testAlias2)
        end
    },
    {
        name = "testAlias3",
        template = "output",
        typeName = "alias",
        groupName = "MMAliases",
        pattern = [[^testAlias3$]],
        expected = "0",
        setupFunc = function(funcName, outputValStr)
            MMGlobals[funcName] = 0
            expandAlias("/alias {"..funcName.."} {/if {$"..funcName.." == 1} {/showme "..outputValStr.." 1} {/showme "..outputValStr.." 0}}")
        end,
        testFunc = function(funcName, outputValStr)
            expandAlias("/"..funcName.." " .. MMGlobals.testAlias2)
        end
    },
    {
        name = "testItemAdd",
        template = "script",
        pattern = [[^testItemAdd$]],
        expected = "test",
        setupFunc = function(funcName, expectedValStr)
            local newValStr = expectedValStr..math.random(100, 999)
            local aliasVal = "/itemadd {"..funcName.."} {"..newValStr.."}"
            expandAlias(aliasVal)
            return newValStr
        end,
        testFunc = function(funcName, expectedValStr)
            if MMCompat.isDebug then
                display(MMGlobals)
            end
            local lastEntryIdx = #MMGlobals[funcName]
            return MMGlobals[funcName] == expectedValStr, MMGlobals[funcName][lastEntryIdx]
        end
    },
    {
        name = "testVariable1",
        template = "script",
        pattern = [[^testVariable1$]],
        expected = "test",
        setupFunc = function(funcName, expectedValStr)
            local newValStr = expectedValStr..math.random(100, 999)
            local aliasVal = "/variable {"..funcName.."} {"..newValStr.."}"
            expandAlias(aliasVal)
            return newValStr
        end,
        testFunc = function(funcName, expectedValStr)
            return MMGlobals[funcName] == expectedValStr, MMGlobals[funcName]
        end
    },
    {
        name = "testVariable2",
        template = "script",
        pattern = [[^testVariable2$]],
        expected = "test",
        setupFunc = function(funcName, expectedValStr)
            local newValStr = expectedValStr..math.random(100, 999)
            local aliasVal = "/variable "..funcName.." {"..newValStr.."}"
            expandAlias(aliasVal)
            return newValStr
        end,
        testFunc = function(funcName, expectedValStr)
            return MMGlobals[funcName] == expectedValStr, MMGlobals[funcName]
        end
    },
    {
        name = "testVariable3",
        template = "script",
        pattern = [[^testVariable3$]],
        expected = "test",
        setupFunc = function(funcName, expectedValStr)
            local newValStr = expectedValStr..math.random(100, 999)
            local aliasVal = "/variable "..funcName.." "..newValStr
            expandAlias(aliasVal)
            return newValStr
        end,
        testFunc = function(funcName, expectedValStr)
            return MMGlobals[funcName] == expectedValStr, MMGlobals[funcName]
        end
    },
    {
        name = "testVariable4",
        template = "script",
        pattern = [[^testVariable4$]],
        expected = "test",
        setupFunc = function(funcName, expectedValStr)
            local newValStr = expectedValStr..math.random(100, 999)
            local aliasVal = "/variable {"..funcName.."} "..newValStr
            expandAlias(aliasVal)
            return newValStr
        end,
        testFunc = function(funcName, expectedValStr)
            return MMGlobals[funcName] == expectedValStr, MMGlobals[funcName]
        end
    },
    {
        name = "testVariable5",
        template = "script",
        pattern = [[^testVariable5$]],
        expected = "test",
        setupFunc = function(funcName, expectedValStr)
            local newValStr = expectedValStr..math.random(100, 999)
            local aliasVal = "/variable "..funcName.." {"..newValStr.."}"
            expandAlias(aliasVal)
            return newValStr
        end,
        testFunc = function(funcName, expectedValStr)
            return MMGlobals[funcName] == expectedValStr, MMGlobals[funcName]
        end
    }
}


for _,v in pairs(MMCompatTest.functions) do
    local aliasId = tempAlias(v.pattern,
        function()
            if v.template == "output" then
                MMCompatTest.testOutputTemplate(v.typeName, v.name, v.groupName, v.setupFunc, v.testFunc, v.expected)
            elseif v.template == "script" then
                MMCompatTest.testScriptTemplate(v.name, v.setupFunc, v.testFunc, v.expected)
            end
        end
    )
    MMCompatTest.echo("Loaded <LawnGreen>"..v.name.." <white>command")
    table.insert(MMCompatTest.scriptAliases, aliasId)
end

table.insert(MMCompatTest.scriptAliases,
    tempAlias("^testAllActions",
        function()
            for _,v in pairs(MMCompatTest.functions) do
                if v.name:find("^testAction") then
                    expandAlias(v.name)
                end
            end
        end
    )
)

table.insert(MMCompatTest.scriptAliases,
    tempAlias("^testAllAliases",
        function()
            for _,v in pairs(MMCompatTest.functions) do
                if v.name:find("^testAlias") then
                    expandAlias(v.name)
                end
            end
        end
    )
)

table.insert(MMCompatTest.scriptAliases,
    tempAlias("^testAllVariables",
        function()
            for _,v in pairs(MMCompatTest.functions) do
                if v.name:find("^testVariable") then
                    expandAlias(v.name)
                end
            end
        end
    )
)