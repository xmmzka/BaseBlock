--[[
    File: ProtectRequire.lua
    Description:
    Author: circute
    Date: 2025-01-11
    Version: 1.0.0
    License: GPL-v3
]]

---@class ProtectRequire
local ProtectRequire = {}
function ProtectRequire.loadModule(moduleName)
    local status, mod = pcall(require, moduleName)
    if status then
        return mod
    else
        return nil
    end
end

return ProtectRequire