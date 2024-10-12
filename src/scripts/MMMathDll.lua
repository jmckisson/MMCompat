MMCompat.add_help('mathdll', [[
Help for Math.dll
=================
Info - Some information about the dll.
Precision - Set the precision of returned results.
Debug - Turns debugging info on/off.  Pass in on or off as the parameter.

All of the following functions take 3 parameters in the format of:
   /calldll Math {function} {nFloat1 nFloat2 nResult} - nFloat1 and nFloat2
   are the numbers the function is working with.  nResult is the name of the
   variable you want the result placed in.

Add - Add the numbers.
Sub - Subtracts the numbers.
Mul - Multiplies the numbers.
Div - Divides the numbers.
Comp - Compares the numbers.  The result is 0 if they are equal.  Less
   than 0 if the first number is less than the second.  Greater than 0 if the
   first number is greater than the second.

The following are some miscellaneous math related functions.

PowerOf - The result of one number to the power of another.
   /calldll {Math} {PowerOf} {10 2 ResultVar} - 10 to the power of 2.
SquareRoot - Square root of a number.
   /calldll {Math} {SquareRoot} {4 ResultVar} - Square root of 4.

The following are bitwise operations.

BitAnd - Compares each bit of the first number with the corresponding bit in
   the second number. If both bits are 1 the corresponding result bit is set
   to 1. /calldll {Math} {BitAnd} {Number Number ResultVar}
BitOr - Compares each bit of the first number with the corresponding bit in
   the second number. If either bit is 1 the corresponding result bit is set
   to 1. /calldll {Math} {BitOr} {Number Number ResultVar}
BitNot - Performs a bitwise not of the number passed in.
   /calldll {Math} {BitNot} {Number ResultVar}
]])

function MMCompat.bitand(a, b)
    local result = 0
    local bitval = 1
    while a > 0 and b > 0 do
      if a % 2 == 1 and b % 2 == 1 then -- test the rightmost bits
          result = result + bitval      -- set the current bit
      end
      bitval = bitval * 2 -- shift left
      a = math.floor(a/2) -- shift right
      b = math.floor(b/2)
    end
    return result
end

local MOD = 2^32

function MMCompat.bitnot(x)
    return(-1 - x) % MOD
end

function MMCompat.bitor(a, b)
    local result = 0
    local power = 1
    while a > 0 or b > 0 do
        local bit_a = a % 2
        local bit_b = b % 2
        local or_bit = (bit_a == 1 or bit_b == 1) and 1 or 0
        result = result + or_bit * power
        power = power * 2
        a = math.floor(a / 2)
        b = math.floor(b / 2)
    end
    return result
end

function MMCompat.doMathDll(funcName, dllParams)
    if funcName == "info" then
        return
    elseif funcName == "precision" then
        -- add configurability for floating point precision
        return

    elseif funcName == "debug" then
        return
    end

    local processedParams, anyMatches = MMCompat.referenceVariables(dllParams, MMGlobals)

    local params = {}
    -- params are delimited by space, last param is the result
    for word in processedParams:gmatch("%S+") do
        table.insert(params, word)
    end

    local mathStr = ""

    -- look for non simple operator functions
    if funcName == "add" then
        if #params ~= 3 then
            MMCompat.warning("Invalid number of parameters to MathDll Add")
            return
        end

        mathStr = string.format("%f + %f", tonumber(params[1]), tonumber(params[2]))

    elseif funcName == "sub" or funcName == "comp" then
        if #params ~= 3 then
            MMCompat.warning("Invalid number of parameters to MathDll Sub or Comp")
            return
        end

        mathStr = string.format("%f - %f", tonumber(params[1]), tonumber(params[2]))
    elseif funcName == "mul" then
        if #params ~= 3 then
            MMCompat.warning("Invalid number of parameters to MathDll Mul")
            return
        end

        mathStr = string.format("%f * %f", tonumber(params[1]), tonumber(params[2]))
    elseif funcName == "div" then
        if #params ~= 3 then
            MMCompat.warning("Invalid number of parameters to MathDll Div")
            return
        end

        mathStr = string.format("%f / %f", tonumber(params[1]), tonumber(params[2]))
    elseif funcName == "powerof" then
        if #params ~= 3 then
            MMCompat.warning("Invalid number of parameters to MathDll PowerOf")
            return
        end

        mathStr = string.format("mth.pow(%f,%f)", tonumber(params[1]), tonumber(params[2]))
    elseif funcName == "squareroot" then
        if #params ~= 2 then
            MMCompat.warning("Invalid number of parameters to MathDll SquareRoot")
            return
        end

        mathStr = string.format("math.sqrt(%f)", tonumber(params[1]))
    elseif funcName == "bitand" then
        if #params ~= 3 then
            MMCompat.warning("Invalid number of parameters to MathDll BitAnd")
            return
        end

        local n1 = tonumber(params[1])
        local n2 = tonumber(params[2])

        if not n1 or not n2 or n1 < 0 or n2 < 0 then
            MMCompat.warning("Invalid integer argument to MathDll BitAnd")
            return
        end

        mathStr = string.format("MMCompat.bitand(%d,%d)", n1, n2)
    elseif funcName == "bitor" then
        if #params ~= 3 then
            MMCompat.warning("Invalid number of parameters to MathDll BitOr")
            return
        end

        local n1 = tonumber(params[1])
        local n2 = tonumber(params[2])

        if not n1 or not n2 or n1 < 0 or n2 < 0 then
            MMCompat.warning("Invalid integer argument to MathDll BitOr")
            return
        end

        mathStr = string.format("MMCompat.bitor(%d,%d)", n1, n2)
    elseif funcName == "bitnot" then
        if #params ~= 2 then
            MMCompat.warning("Invalid number of parameters to MathDll BitAnd")
            return
        end

        local n1 = tonumber(params[1])

        if not n1 or n1 < 0 then
            MMCompat.warning("Invalid integer argument to MathDll BitAnd")
            return
        end

        mathStr = string.format("MMCompat.bitnot(%d)", n1)

    else
        MMCompat.warning("Math function not defined: "..funcName)
        return
    end
    
    MMCompat.debug("CallDll processing Math: "..mathStr)

    local mathResult = MMCompat.procMath(mathStr)

    if not mathResult then
        MMCompat.warning("Invalid result from Math processing")
        return
    end

    MMGlobals[params[3]] = mathResult

    local varTbl = {
        name = params[3],
        group = ""
    }

    return varTbl
end