--[[
    File: Enums.lua
    Description:
    Author: circute
    Date: 2025-01-07
    Version: 1.0.0
    License: GPL-v3
]]

---@enum LogLevel
local LogLevel = {
    DISABLE = -1,
    DEBUG = 0,
    INFO = 1,
    WARN = 2,
    ERROR = 3,
    FATAL = 4
}

---@enum ObjectType
local ObjectType = {
    COMPONENT = 0,
    TRIGGER = 1,
    LOGICAL = 2,
    EFFECT = 3
}

local Enums = {}

Enums.LogLevel = LogLevel
Enums.ObjectType = ObjectType


return Enums
