--[[
    File: ConfigLoader.lua
    Description:
    Author: circute
    Date: 2025-01-07
    Version: 1.0.0
    License: GPL-v3
]]

local Enums = require("Enums")
local ProtectRequire = require("ProtectRequire")


-- Do not return this class
---@class ConfigLoader
local ConfigLoader = {}

ConfigLoader.config = {
    logLevel = Enums.LogLevel.INFO,
    enableTest = true,
    runTestFrameOffset = 30
}

function ConfigLoader.loadConfig(configName)
    local configData = ProtectRequire.loadModule(configName)
    if not configData then
        return nil
    else
        local totalConfigItemCount = 0
        local loadedCount = 0
        local skipCount = 0
        for key, value in pairs(configData) do
            totalConfigItemCount = totalConfigItemCount + 1
            if ConfigLoader.config[key] ~= nil and type(ConfigLoader.config[key]) == type(value) then
                ConfigLoader.config[key] = value
                loadedCount = loadedCount + 1
            else
                skipCount = skipCount + 1
            end
        end

        local result = {
            total = totalConfigItemCount,
            loaded = loadedCount,
            skipped = skipCount,
        }
        return result
    end
end

return ConfigLoader