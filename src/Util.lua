--[[
    File: Util.lua
    Description:
    Author: circute
    Date: 2025-01-07
    Version: 1.0.0
    License: GPL-v3
]]

---@class Util
local Util = {}

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

return Util