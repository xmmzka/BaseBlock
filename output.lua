--[[
Package Information:
Author: circute
Description: No description provided
Package Time: 2025-01-11 04:12:41
Package Folder: ./src/
Modules: 10
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
    local nnnen_testMetaData = ProtectRequire.loadModule(testName)
    if nnnen_testMetaData then
        Test.testFunctionList = {}
        Test.enableStatusList = {}
        for key, value in pairs(nnnen_testMetaData) do
            if type(value) == "function" then
                Test.testFunctionList[key] = value
                Test.enableStatusList[key] = nnnen_testMetaData[key .. "enabled"] and true
            end
        end
    end
end
function Core.runTest()
    local nnnen_success = 0
    local nnnen_failure = 0
    local nnnen_total = 0
    local nnnen_outputCache = {}
    for key, value in pairs(Test.testFunctionList) do
        if Test.enableStatusList[key] then
            nnnen_total = nnnen_total + 1
            local status, result = pcall(value())
            if status then
                nnnen_success = nnnen_success + 1
            else
                nnnen_failure = nnnen_failure + 1
                nnnen_outputCache[key] = result
            end
        end
    end
    local nnnen_outputHeader = string.format("UNIT TEST\nframe count: %s\ntotal: %s\nsuccess: %s\nfailure: %s\ntest list address:%s\n\n", Core.frameCount, nnnen_total, nnnen_success, nnnen_failure, Test.testFunctionList)
    local nnnen_outputBody = ""
    for key, value in pairs(nnnen_outputCache) do
        nnnen_outputBody = nnnen_outputBody .. string.format("-> function: %s\n    info:%s\n\n", key, value)
    end
    local outputTail
    if nnnen_success == nnnen_total then
        outputTail = "==> SUCCESS"
    else
        outputTail = "==> FAILURE"
    end
    print(nnnen_outputHeader .. nnnen_outputBody .. outputTail)
end
ConfigLoader.config = {
    logLevel = Enums.LogLevel.INFO,
    enableTest = true,
    runTestFrameOffset = 30
}
function ConfigLoader.loadConfig(configName)
    local esnov_configData = ProtectRequire.loadModule(configName)
    if not esnov_configData then
        return nil
    else
        local esnov_totalConfigItemCount = 0
        local esnov_loadedCount = 0
        local esnov_skipCount = 0
        for key, value in pairs(esnov_configData) do
            esnov_totalConfigItemCount = esnov_totalConfigItemCount + 1
            if ConfigLoader.config[key] ~= nil and type(ConfigLoader.config[key]) == type(value) then
                ConfigLoader.config[key] = value
                esnov_loadedCount = esnov_loadedCount + 1
            else
                esnov_skipCount = esnov_skipCount + 1
            end
        end
        local esnov_result = {
            total = esnov_totalConfigItemCount,
            loaded = esnov_loadedCount,
            skipped = esnov_skipCount,
        }
        return esnov_result
    end
end
local function hasyf_getLogLevelName(logLevel)
    return Util.keyOf(Enums.LogLevel, logLevel)
end
local hasyf_lowProtoLogApi = function(message)
    GlobalAPI.debug(message)
end
local hasyf_midProtoLogApi = function(message)
    GlobalAPI.warning(message)
end
local hasyf_emgProtoLogApi = function(message)
    GlobalAPI.error(message)
end
local hasyf_logOutputAdapter = {
    [Enums.LogLevel.DISABLE] = nil,
    [Enums.LogLevel.DEBUG] = hasyf_lowProtoLogApi,
    [Enums.LogLevel.INFO] = hasyf_lowProtoLogApi,
    [Enums.LogLevel.WARN] = hasyf_midProtoLogApi,
    [Enums.LogLevel.ERROR] = hasyf_emgProtoLogApi,
    [Enums.LogLevel.FATAL] = hasyf_emgProtoLogApi
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
        local hasyf_outputString = string.format("[ %s ] @ [ %s ] ==> %s", hasyf_getLogLevelName(logLevel), Core.frameCount, message)
        hasyf_logOutputAdapter[logLevel](hasyf_outputString)
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
return BaseBlock