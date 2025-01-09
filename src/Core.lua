--[[
    File: Core.lua
    Description:
    Author: circute
    Date: 2025-01-07
    Version: 1.0.0
    License: GPL-v3
]]

local Test = require("Test")
local Logger = require("Logger")

-- Do not return this class.
---@class Core
---@field CORE_VERSION string
---@field LOGICAL_FRAME_RATE number
---@field FRAME_INTERVAL number
---@field frameCount number
---@field frameworkFixedUpdateSequence table
---@field frameworkLateUpdateSequence table
---@field fixedUpdateSequence table
---@field lateUpdateSequence table
local Core = {
    CORE_VERSION = "0.0.1_20250107-Alpha",
    LOGICAL_FRAME_RATE = 30,
    FRAME_INTERVAL = 0.0333333333,

    frameCount = 0,
    frameworkFixedUpdateSequence = {},
    frameworkLateUpdateSequence = {},
    fixedUpdateSequence = {},
    lateUpdateSequence = {}
}

function Core.preHandlerWrapper()
    for _, value in pairs(Core.frameworkFixedUpdateSequence) do
        value()
    end
    for _, value in pairs(Core.fixedUpdateSequence) do
        value()
    end
end

function Core.lateHandlerWrapper()
    for _, value in pairs(Core.frameworkLateUpdateSequence) do
        value()
    end
    for _, value in pairs(Core.lateUpdateSequence) do
        value()
    end
    -- update after current frame.
    Core.frameCount = Core.frameCount + 1
end

function Core.init()
    -- regester frame updater.
    LuaAPI.set_tick_handler(Core.preHandlerWrapper, Core.lateHandlerWrapper)
    Logger.info("Core initialization is complete.")
end

function Core.getFrameTime()
    return Core.frameCount * Core.FRAME_INTERVAL
end

function Core.loadTestFunctionList(testName)
    local testMetaData = require(testName)
    if testMetaData then
        Test.testFunctionList = {}
        Test.enableStatusList = {}
        for key, value in pairs(testMetaData) do
            if type(value) == "function" then
                Test.testFunctionList[key] = value
                Test.enableStatusList[key] = testMetaData[key .. "enabled"] and true
            end
        end
    end
end

function Core.runTest()
    local frameCount = Core.frameCount
    local success = 0
    local failure = 0
    local total = 0
    local outputCache = {}
    for key, value in pairs(Test.testFunctionList) do
        if Test.enableStatusList[key] then
            total = total + 1
            local status, result = pcall(value())
            if status then
                success = success + 1
            else
                failure = failure + 1
                outputCache[key] = result
            end
        end
    end
    
    local outputHeader = string.format("UNIT TEST\nframe count: %s\ntotal: %s\nsuccess: %s\nfailure: %s\ntest list address:%s\n\n", frameCount, total, success, failure, Test.testFunctionList)
    local outputBody = ""
    for key, value in pairs(outputCache) do
        outputBody = outputBody .. string.format("-> function: %s\n    info:%s\n\n", key, value)
    end
    local outputTail
    if success == total then
        outputTail = "==> SUCCESS"
    else
        outputTail = "==> FAILURE"
    end
    print(outputHeader .. outputBody .. outputTail)
end


return Core