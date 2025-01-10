--[[
    File: Logger.lua
    Description:
    Author: circute
    Date: 2025-01-07
    Version: 1.0.0
    License: GPL-v3
]]

local Enums = require("Enums")
local Core = require("Core")
local Util = require("Util")
local ConfigLoader = require("ConfigLoader")

---@class Logger
local Logger = {}

-- private:
local function getLogLevelName(logLevel)
    return Util.keyOf(Enums.LogLevel, logLevel)
end

local lowProtoLogApi = function(message)
    GlobalAPI.debug(message)
end

local midProtoLogApi = function(message)
    GlobalAPI.warning(message)
end

local emgProtoLogApi = function(message)
    GlobalAPI.error(message)
end

-- Do not return this table.
local logOutputAdapter = {
    [Enums.LogLevel.DISABLE] = nil,
    [Enums.LogLevel.DEBUG] = lowProtoLogApi,
    [Enums.LogLevel.INFO] = lowProtoLogApi,
    [Enums.LogLevel.WARN] = midProtoLogApi,
    [Enums.LogLevel.ERROR] = emgProtoLogApi,
    [Enums.LogLevel.FATAL] = emgProtoLogApi
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
        local outputString = string.format("[ %s ] @ [ %s ] ==> %s", getLogLevelName(logLevel), Core.frameCount, message)
        logOutputAdapter[logLevel](outputString)
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

return Logger
