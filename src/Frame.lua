--[[
    File: Frame.lua
    Description:
    Author: circute
    Date: 2025-01-07
    Version: 1.0.0
    License: GPL-v3
]]

local Core = require("Core")

---@class Frame
local Frame = {}
function Frame.getFixedUpdateFunctionSequence()
    return Core.fixedUpdateSequence
end

function Frame.getLateUpdateFunctionSequence()
    return Core.lateUpdateSequence
end

function Frame.getFrameCount()
    return Core.frameCount
end

return Frame
