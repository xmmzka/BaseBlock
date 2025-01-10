--[[
Package Information:
Author: circute
Description: No description provided
Package Time: 2025-01-11 05:28:36
Package Folder: ./src/
Modules: 11
]]

-- Modules:
-- Enums
-- Core
-- ConfigLoader
-- Logger
-- FrameTimer
-- Frame
-- Test
-- Timer
-- Util
-- Random
-- ProtectRequire

local Enums = {}
local Core = {}
local ConfigLoader = {}
local Logger = {}
local FrameTimer = {}
local Frame = {}
local Test = {}
local Timer = {}
local Util = {}
local Random = {}
local ProtectRequire = {}
local LogLevel = {
    DISABLE = -1,
    DEBUG = 0,
    INFO = 1,
    WARN = 2,
    ERROR = 3,
    FATAL = 4
}
local ObjectType = {
    COMPONENT = 0,
    TRIGGER = 1,
    LOGICAL = 2,
    EFFECT = 3
}
Enums.LogLevel = LogLevel
Enums.ObjectType = ObjectType
Core.CORE_VERSION = "0.0.1_20250107-Alpha"
Core.LOGICAL_FRAME_RATE = 30
Core.FRAME_INTERVAL = 0.0333333333
Core.frameCount = 0
Core.frameworkFixedUpdateSequence = {}
Core.frameworkLateUpdateSequence = {}
Core.fixedUpdateSequence = {}
Core.lateUpdateSequence = {}
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
    
    Core.frameCount = Core.frameCount + 1
end
function Core.init()
    Core.frameCount = 1
    
    LuaAPI.set_tick_handler(Core.preHandlerWrapper, Core.lateHandlerWrapper)
    Logger.info("Core initialization is complete.")
end
function Core.getFrameTime()
    return Core.frameCount * Core.FRAME_INTERVAL
end
function Core.loadTestFunctionList(testName)
    local vmffn_testMetaData = ProtectRequire.loadModule(testName)
    if vmffn_testMetaData then
        Test.testFunctionList = {}
        Test.enableStatusList = {}
        for key, value in pairs(vmffn_testMetaData) do
            if type(value) == "function" then
                Test.testFunctionList[key] = value
                Test.enableStatusList[key] = vmffn_testMetaData[key .. "enabled"] and true
            end
        end
    end
end
function Core.runTest()
    local vmffn_success = 0
    local vmffn_failure = 0
    local vmffn_total = 0
    local vmffn_outputCache = {}
    for key, value in pairs(Test.testFunctionList) do
        if Test.enableStatusList[key] then
            vmffn_total = vmffn_total + 1
            local status, result = pcall(value())
            if status then
                vmffn_success = vmffn_success + 1
            else
                vmffn_failure = vmffn_failure + 1
                vmffn_outputCache[key] = result
            end
        end
    end
    local vmffn_outputHeader = string.format("UNIT TEST\nframe count: %s\ntotal: %s\nsuccess: %s\nfailure: %s\ntest list address:%s\n\n", Core.frameCount, vmffn_total, vmffn_success, vmffn_failure, Test.testFunctionList)
    local vmffn_outputBody = ""
    for key, value in pairs(vmffn_outputCache) do
        vmffn_outputBody = vmffn_outputBody .. string.format("-> function: %s\n    info:%s\n\n", key, value)
    end
    local outputTail
    if vmffn_success == vmffn_total then
        outputTail = "==> SUCCESS"
    else
        outputTail = "==> FAILURE"
    end
    print(vmffn_outputHeader .. vmffn_outputBody .. outputTail)
end
ConfigLoader.config = {
    logLevel = Enums.LogLevel.INFO,
    enableTest = true,
    runTestFrameOffset = 30
}
function ConfigLoader.loadConfig(configName)
    local mttyq_configData = ProtectRequire.loadModule(configName)
    if not mttyq_configData then
        return nil
    else
        local mttyq_totalConfigItemCount = 0
        local mttyq_loadedCount = 0
        local mttyq_skipCount = 0
        for key, value in pairs(mttyq_configData) do
            mttyq_totalConfigItemCount = mttyq_totalConfigItemCount + 1
            if ConfigLoader.config[key] ~= nil and type(ConfigLoader.config[key]) == type(value) then
                ConfigLoader.config[key] = value
                mttyq_loadedCount = mttyq_loadedCount + 1
            else
                mttyq_skipCount = mttyq_skipCount + 1
            end
        end
        local mttyq_result = {
            total = mttyq_totalConfigItemCount,
            loaded = mttyq_loadedCount,
            skipped = mttyq_skipCount,
        }
        return mttyq_result
    end
end
local function wikpc_getLogLevelName(logLevel)
    return Util.keyOf(Enums.LogLevel, logLevel)
end
local wikpc_lowProtoLogApi = function(message)
    GlobalAPI.debug(message)
end
local wikpc_midProtoLogApi = function(message)
    GlobalAPI.warning(message)
end
local wikpc_emgProtoLogApi = function(message)
    GlobalAPI.error(message)
end
local wikpc_logOutputAdapter = {
    [Enums.LogLevel.DISABLE] = nil,
    [Enums.LogLevel.DEBUG] = wikpc_lowProtoLogApi,
    [Enums.LogLevel.INFO] = wikpc_lowProtoLogApi,
    [Enums.LogLevel.WARN] = wikpc_midProtoLogApi,
    [Enums.LogLevel.ERROR] = wikpc_emgProtoLogApi,
    [Enums.LogLevel.FATAL] = wikpc_emgProtoLogApi
}
function Logger.getCurrentLogLevel()
    return ConfigLoader.config.logLevel
end
function Logger.setCurrentLogLevel(logLevel)
    if Util.contains(Enums.LogLevel, logLevel) then
        ConfigLoader.config.logLevel = logLevel
    else
        Logger.error("The parameter is incorrect, and the modification does not take effect.")
    end
end
function Logger.log(logLevel, message)
    if logLevel ~= Enums.LogLevel.DISABLE and logLevel >= Logger.getCurrentLogLevel() then
        local wikpc_outputString = string.format("[ %s ] @ [ %s ] ==> %s", wikpc_getLogLevelName(logLevel), Core.frameCount, message)
        wikpc_logOutputAdapter[logLevel](wikpc_outputString)
    end
end
function Logger.debug(message)
    Logger.log(Enums.LogLevel.DEBUG, message)
end
function Logger.info(message)
    Logger.log(Enums.LogLevel.INFO, message)
end
function Logger.warn(message)
    Logger.log(Enums.LogLevel.WARN, message)
end
function Logger.error(message)
    Logger.log(Enums.LogLevel.ERROR, message)
end
function Logger.fatal(message)
    Logger.log(Enums.LogLevel.FATAL, message)
end
FrameTimer.intervalFrames = 1
FrameTimer.count = 1
FrameTimer.currentCount = 0
FrameTimer.immediate = false
FrameTimer.task = function() end
FrameTimer.enabled = false
FrameTimer.destroyed = false
FrameTimer.wrappedCallback = function() end
FrameTimer.__index = FrameTimer
function FrameTimer.new(intervalFrames, count, immediate, task)
    local self = setmetatable({}, FrameTimer)
    self.intervalFrames = intervalFrames or 1
    self.count = count or 1
    self.currentCount = 0
    self.immediate = immediate or false
    self.task = task
    self.enabled = false
    self.destroyed = false
    self.wrappedCallback = function()
        if self.currentCount < self.count and self.enabled then
            self.currentCount = self.currentCount + 1
            LuaAPI.call_delay_frame(self.intervalFrames, self.wrappedCallback)
            self.task()
        else
            self.enabled = false
            self.destroyed = true
        end
    end
    return self
end
function FrameTimer:run()
    if self.enabled then
        Logger.error("The timer is running and cannot be enabled repeatedly.")
        return
    elseif self.destroyed then
        Logger.error("The timer has run out.")
        return
    end
    if self.count == 0 then
        return
    end
    self.enabled = true
    if self.immediate then
        self.currentCount = self.currentCount + 1
        LuaAPI.call_delay_frame(self.intervalFrames, self.wrappedCallback)
        self.task()
    else
        LuaAPI.call_delay_frame(self.intervalFrames, self.wrappedCallback)
    end
end
function FrameTimer:destroy()
    self.enabled = false
    self.destroyed = true
end
function Frame.getFixedUpdateFunctionSequence()
    return Core.fixedUpdateSequence
end
function Frame.getLateUpdateFunctionSequence()
    return Core.lateUpdateSequence
end
function Frame.getFrameCount()
    return Core.frameCount
end
Test.testFunctionList = {}
Test.enableStatusList = {}
function Test.assert(expect, actual)
    if expect ~= actual then
        error(string.format("Assertion failed.\nexpect: %s,\nactual: %s", expect, actual), 2)
    end
end
Timer.interval = 1.0
Timer.count = 1
Timer.currentCount = 0
Timer.immediate = false
Timer.task = function() end
Timer.enabled = false
Timer.destroyed = false
Timer.wrappedCallback = function() end
Timer.__index = Timer
function Timer.new(interval, count, immediate, task)
    local self = setmetatable({}, Timer)
    self.interval = interval + 0.0 or 1.0
    self.count = count or 1
    self.currentCount = 0
    self.immediate = immediate or false
    self.task = task
    self.enabled = false
    self.destroyed = false
    self.wrappedCallback = function()
        if self.currentCount < self.count and self.enabled then
            self.currentCount = self.currentCount + 1
            LuaAPI.call_delay_time(self.interval, self.wrappedCallback)
            self.task()
        else
            self.enabled = false
            self.destroyed = true
        end
    end
    return self
end
function Timer:run()
    if self.enabled then
        Logger.error("The timer is running and cannot be enabled repeatedly.")
        return
    elseif self.destroyed then
        Logger.error("The timer has run out.")
        return
    end
    if self.count == 0 then
        return
    end
    self.enabled = true
    if self.immediate then
        self.currentCount = self.currentCount + 1
        LuaAPI.call_delay_time(self.interval, self.wrappedCallback)
        self.task()
    else
        LuaAPI.call_delay_time(self.interval, self.wrappedCallback)
    end
end
function Timer:destroy()
    self.enabled = false
    self.destroyed = true
end
function Util.indexOf(array, elem)
    for index, value in ipairs(array) do
        if value == elem then
            return index
        end
    end
    return nil
end
function Util.contains(table, elem)
    for _, value in pairs(table) do
        if value == elem then
            return true
        end
    end
    return false
end
function Util.keyOf(table, elem)
    for key, value in pairs(table) do
        if value == elem then
            return key
        end
    end
    return nil
end
Random.seed = 61
Random.state = 61
Random.__index = Random
function Random.new(seed)
    local self = setmetatable({}, Random)
    self.seed = seed or 61
    self.state = self.seed
    return self
end
function Random:nextInt(bound)
    local wuuih_xstate = self.state
    wuuih_xstate = wuuih_xstate ~ (wuuih_xstate << 21)
    wuuih_xstate = wuuih_xstate ~ (wuuih_xstate >> 35)
    wuuih_xstate = wuuih_xstate ~ (wuuih_xstate << 4)
    self.state = wuuih_xstate
    local wuuih_rand = wuuih_xstate * 2685821657736338717 % (2 ^ 32)
    if bound then
        return wuuih_rand % bound
    else
        return wuuih_rand
    end
end
function Random:nextBoolean()
    return self:nextInt() % 2 == 0
end
function Random:nextFloat()
    return self:nextInt() / 2 ^ 32
end
function ProtectRequire.loadModule(moduleName)
    local status, mod = pcall(require, moduleName)
    if status then
        return mod
    else
        return nil
    end
end
local BaseBlock = {}
--Load logic
local title = string.format("BaseBlock Framework\n>>> V%s\n", Core.CORE_VERSION)
print(title)
local configStatus = ConfigLoader.loadConfig("config")
if configStatus then
    Logger.info(string.format("Profiles found, total number of configurations: %s, loaded: %s, skipped: %s.", configStatus.total, configStatus.loaded, configStatus.skipped))
else
    Logger.info("No profile found, default value used.")
end
Logger.info("Log level has been set to " .. ConfigLoader.config.logLevel .. ".")
Core.init()
Core.loadTestFunctionList("test")
FrameTimer.new(ConfigLoader.config.runTestFrameOffset, 1, false, function ()
    Core.runTest()
end):run()
BaseBlock.LogLevel = Enums.LogLevel
BaseBlock.ObjectType = Enums.ObjectType
BaseBlock.Frame = Frame
BaseBlock.FrameTimer = FrameTimer
BaseBlock.Logger = Logger
BaseBlock.Test = Test
BaseBlock.Timer = Timer
BaseBlock.Util = Util
BaseBlock.Random = Random
return BaseBlock