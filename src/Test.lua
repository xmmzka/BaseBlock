--[[
    File: Test.lua
    Description:
    Author: circute
    Date: 2025-01-09
    Version: 1.0.0
    License: GPL-v3
]]

---@class Test
local Test = {}
Test.testFunctionList = {}
Test.enableStatusList = {}

function Test.assert(expect, actual)
    if expect ~= actual then
        error(string.format("Assertion failed.\nexpect: %s,\nactual: %s", expect, actual), 2)
    end
end

return Test
